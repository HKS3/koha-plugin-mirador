package Koha::Plugin::HKS3::IIIF;

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This program comes with ABSOLUTELY NO WARRANTY;

use Modern::Perl;

use Data::UUID;
use HTTP::Tiny;
use JSON;
use List::Util qw(max sum);
use Koha::Caches;
use CAM::PDF;
use URI::Encode qw(uri_encode uri_decode);

our @EXPORT = qw(create_iiif_manifest);

sub create_paths_from_pdf {
    my ($pdf_file, $name, $config) = @_;
    my @images;
    my $pdf = CAM::PDF->new($pdf_file) or return @images; # die "$pdf_file Cannot open PDF file: $!";    
    my $num_pages = $pdf->numPages();
    for my $i (1..$pdf->numPages()) {
        push(@images, sprintf("%s;%d", $name, $i));
    }
    return @images;
}

my $ug = Data::UUID->new;
sub generate_id {
    return sprintf('http://%s', $ug->to_string($ug->create())) ;
}

sub create_canvases {
    my ($images, $config) = @_;

    my @canvases;
    my $count = 1;

    my $cache = Koha::Caches->get_instance(__PACKAGE__);

    for my $entry (@$images) {
        # we may get multiple per canvas, e.g. transcripts
        my @elements;

        my @paths;
        if (ref $entry eq 'ARRAY') {
            @paths = @$entry;
        } else {
            @paths = $entry;
        }

        for my $path (@paths) {
            my $image_info = $cache->get_from_cache($path);
            unless ($image_info) {
                my $http = HTTP::Tiny->new;
                #warn "Querying image info for $path";
                my $response = $http->get(sprintf('%s/%s/info.json', $config->{iiif_server}, $path));

                if (!$response) {
                    warn "Failed to obtain info.json for $path, skipping it in the manifest";
                    next;
                }

                $image_info = decode_json $response->{content};
                $cache->set_in_cache($path, $image_info);
            }

            push @elements, {
                path => $path,
                width => $image_info->{width},
                height => $image_info->{height},
                motivation => @elements ? 'sc:supplementing' : 'sc:painting',
            };
        }

        my $canvas_id = generate_id();
        my $xpos = 0;
        my $padding = 10;

        my $max_height = max map { $_->{height} } @elements;
        my $total_width = (sum map { $_->{width} } @elements) + $padding * (@elements - 1);

        my $annotation_for_element = sub {
            my $element = shift;

            my $annotation = {
                '@id'        =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $element->{path}),
                '@context'   => 'http://iiif.io/api/presentation/2/context.json',
                '@type'      => 'oa:Annotation',
                'motivation' => $element->{motivation},
                'resource'   => {
                    '@id'     => sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $element->{path}),
                    '@type'   => 'dctypes:Image',
                    'format'  => 'image/jpeg',
                    'height' => $element->{height},
                    'width'  => $element->{width},
                    'service' => {
                        '@context' => 'http://iiif.io/api/image/3/context.json',
                        '@id'      => sprintf('%s/%s', $config->{iiif_server}, $element->{path}),
                        'profile'  => 'level2'
                    },
                },
                'on' => "$canvas_id#xywh=$xpos,0,$element->{width},$element->{height}",
            };

            $xpos += $element->{width} + $padding;
            return $annotation;
        };

        my $canvas_template = {
            '@id'    => $canvas_id,
            '@type'  => 'sc:Canvas',
            'label'  => sprintf("# %s", $count),
            # TODO fix this stupid-ass hack somehow
            # this nonsense here keeps the aspect ratio similar-ish which reduces stupid thumbnail padding in Mirador, but it also makes the actual canvas zoomed out
            'height' => $max_height * @elements,
            'width'  => $total_width,
            'images' => [map { $annotation_for_element->($_) } @elements],
            'related' => ''
        };
        if (@elements > 1) {
            $canvas_template->{thumbnail} = $canvas_template->{images}[0]{resource};
        }
        push (@canvases, $canvas_template);

        $count++;
    }

    return @canvases;
}

sub create_iiif_manifest {
    my ($record_data, $config, $canvas_template, $manifest_template) = @_;

    my @canvases = @{$record_data->{canvases}};
    push @canvases, create_canvases($record_data->{image_data}, $config);

    my %labels = (
        title => {
            en => 'Title',
            ger => 'Titel',
        },
        personal_name => {
            en => 'Personal Name',
            ger => 'Personenname',
        },
        type => {
            en => 'Type',
            ger => 'Typ',
        },
        place_of_publications => {
            en => 'Place of Publications',
            ger => 'Erscheinungsort',
        },
        date_issued => {
            en => 'Date Issued',
            ger => 'Erscheinungsdatum',
        },
        extent => {
            en => 'Extent',
            ger => 'Umfang',
        },
        signature => {
            en => 'Signature',
            ger => 'Signatur',
        },
        language => {
            en => 'Languages',
            ger => 'Sprachen',
        },
        # {
        #     'label' => [
        #         { '@value' => 'Id', '@language' => 'en' },
        #         { '@value' => 'Id', '@language' => 'ger' }
        #     ],
        #     'value' => 'wrz17030823'
        #     # Dürfte sich um die Quelle der Dateien handeln, also bei uns der Ordnername ??? -> dann wäre es z.B. KLZ-2020-10-25 ????
        # },
        # {
        #     'label' => [
        #         { '@value' => 'Disseminator', '@language' => 'en' },
        #         { '@value' => 'Anbieter', '@language' => 'ger' }
        #     ],
        #     'value' => 'RaraBib'
        # },
    );

    my @metadata;
    for my $key (%labels) {
        next unless $record_data->{$key};
        push @metadata, {
            'label' => [
                {
                    '@value' => $labels{$key}{en},
                    '@language' => 'en'
                },
                {
                    '@value' => $labels{$key}{ger},
                    '@language' => 'ger'
                }
            ],
            'value' => $record_data->{$key},
        },
    }

    $manifest_template = {
        '@context'  => 'http://iiif.io/api/presentation/2/context.json',
        '@id'       => generate_id(),
        '@type'     => 'sc:Manifest',
        'label'     => $record_data->{title},
        'thumbnail' => {
            '@id' => "http://10.0.0.200:8182/iiif/2/roseggern/full/200,/0/default.jpg",
            'service' => {
                '@context' => "http://iiif.io/api/image/2/context.json",
                'profile'  => "http://iiif.io/api/image/2/level2.json",
                '@id'      => "http://10.0.0.200:8182/iiif/2/roseggern"
            }
        },
        'metadata' => \@metadata,
        #'description' => 'Wiener Zeitung 1703-08-23',  ## ???
        #'description' =>  [
        #    {
        #        '@value' =>  '',
        #        '@language' =>  'en'
        #    }
        #],
        'viewingDirection' => 'left-to-right',
         # 'viewingHint' => 'paged',
        'license' => 'http://creativecommons.org/publicdomain/mark/1.0/', ### muss noch besprochen werden!!!!!
        'attribution' => $config->{attribution},
        'logo' => '/api/v1/contrib/hks3_mirador/static/hks3-logo.png',
        'seeAlso' => [ ### XXX müssen wir noch besprechen, bzw. erarbeiten
            {
              '@id' => 'http://anno.onb.ac.at/cgi-content/anno_pdf.pl?aid=wrz&datum=17030823',
              'format' => 'application/pdf'
            },
            {
              '@id' => 'http://anno.onb.ac.at/cgi-content/anno?aid=wrz&datum=17030823',
              'format' => 'text/html'
            },
            {
              '@id' => 'http://data.onb.ac.at/ANNO/wrz17030823.rdf',
              'format' => 'application/rdf+xml'
            }
        ],
        'license' =>  'https://creativecommons.org/licenses/by/3.0/',
        'sequences' => [
            {
            '@id' => 'http://f617846c-3c25-4fa8-bf18-ab91ebf35c3d',
            '@type' => 'sc:Sequence',
            'label' => [
                {
                    '@value' =>  'Normal Sequence',
                    '@language' =>  'en'
                }
            ],
            'canvases' =>   
                \@canvases                    
            }
        ],
        'structures' =>  []
    };
    
    return $manifest_template;
}

1;
