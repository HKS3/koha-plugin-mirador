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
use Koha::Caches;
use CAM::PDF;
use URI::Encode qw(uri_encode uri_decode);

our @EXPORT = qw(create_iiif_manifest);

sub create_iiif_manifest_from_pdf {
    my ($pdf_file, $name, $config, $filename) = @_;    
    my @images;
    my $pdf = CAM::PDF->new($pdf_file) or return @images; # die "$pdf_file Cannot open PDF file: $!";    
    my $num_pages = $pdf->numPages();
    for my $i (1..$pdf->numPages()) {
        push(@images, sprintf("%s;%d", $name, $i));
    }
    return @images;
}

sub create_iiif_manifest {
    my ($record_data, $config, $canvas_template, $manifest_template) = @_;
    
    my $ug = Data::UUID->new;
    my $generate_id = sub { sprintf('http://%s', $ug->to_string($ug->create())) };

    my $cache = Koha::Caches->get_instance(__PACKAGE__);
    
    my @canvases;
    my $count = 1;
    for my $d (@{$record_data->{image_data}}) {
        $d = uri_encode($d);
        # remove double uri encoding - XXX
        $d =~ s/%252F/%2F/g;

        my $image_info = $cache->get_from_cache($d);
        unless ($image_info) {
            my $http = HTTP::Tiny->new;
            warn "Querying image info for $d";
            my $response = $http->get(sprintf('%s/%s/info.json', $config->{iiif_server}, $d));

            if (!$response) {
                warn "Failed to obtain info.json for $d, skipping it in the manifest";
                next;
            }

            $image_info = decode_json $response->{content};
            $cache->set_in_cache($d, $image_info);
        }

        $canvas_template = {
            '@id'    => $generate_id->(),
            '@type'  => 'sc:Canvas',
            'label'  => sprintf("# %s", $count),
            'height' => $image_info->{height},
            'width'  => $image_info->{width},
            'images' => [{
                '@id'        =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $d),
                '@context'   => 'http://iiif.io/api/presentation/2/context.json',
                # '@type'    => 'oa:Annotation',
                'motivation' => 'sc:painting',
                'resource'   =>  {
                    '@id'     => sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $d),
                    '@type'   => 'dctypes:Image',
                    'format'  => 'image/jpeg',
                    'height'  => 2805,
                    'width'   => 1760,
                    'service' => {
                        '@context' => 'http://iiif.io/api/image/3/context.json',
                        '@id'      => sprintf('%s/%s', $config->{iiif_server}, $d),
                        'profile'  => 'level2'
                    },
                },
                'on' => $generate_id->(),
            }],
            'related' => ''
        };
        push (@canvases, $canvas_template);
        $count++;
    }

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
        '@id'       => $generate_id->(),
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
        'description' => 'Wiener Zeitung 1703-08-23',  ## ???
        'viewingDirection' => 'left-to-right',
         # 'viewingHint' => 'paged',
        'license' => 'http://creativecommons.org/publicdomain/mark/1.0/', ### muss noch besprochen werden!!!!!
        'attribution' => [
            {
                '@value' => 'Austrian National Library',	## XXX	Fixwert: Styrian State Library
                '@language' => 'en'
            },
            {
                '@value' => 'Österreichische Nationalbibliothek',	# XXX Fixwert: Steiermärkische Landesbibliothek
                '@language' => 'ger'
            }
        ],
        'logo' => 'https://iiif.onb.ac.at/logo/',  ### XXX wird nachgeliefert der Link zu unserem LOGO
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
        'description' =>  [
            {
                '@value' =>  '',
                '@language' =>  'en'
            }
        ],
        'license' =>  'https://creativecommons.org/licenses/by/3.0/',
        'attribution' =>  '',
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
