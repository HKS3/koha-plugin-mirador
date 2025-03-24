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

use Cwd qw(abs_path);
use Data::UUID;
use File::Slurp;
use HTTP::Tiny;
use Try::Tiny;
use Template;
use CAM::PDF;
use File::Spec;

our @EXPORT = qw(create_iiif_manifest);

sub create_iiif_manifest_from_pdf {
    my ($pdf_file, $name, $config, $filename) = @_;    
    my $pdf = CAM::PDF->new($pdf_file) or die "$pdf_file Cannot open PDF file: $!";    
    my $num_pages = $pdf->numPages();
    my @images;
    for my $i (1..$pdf->numPages()) {
        push(@images, sprintf("%s;%d", $name, $i));
    }
    return @images;
}


sub create_iiif_manifest {
    my ($record_data, $config, $canvas_template, $manifest_template) = @_;
    
 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg/full/full/0/default.jpg',
 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg',
    my $ug = Data::UUID->new;
    my @canvases;
    # IIIF templates should be template toolkit
    my $count = 1;
    for my $d (@{$record_data->{image_data}}) {

        $canvas_template = {
                '@id' =>  sprintf('http://%s', $ug->to_string($ug->create())),
                '@type' =>  'sc:Canvas',
                'label' =>  sprintf("# %s", $count),
                'height' =>  2805,
                'width' =>  1760,
                'images' =>  [
                    {
                    '@context' =>  'http://iiif.io/api/presentation/2/context.json',
                    '@id' =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $d),                    
                    # '@type' =>  'oa:Annotation',
                    'motivation' =>  'sc:painting',
                    'resource' =>  {
                        # '@id' =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{server}, $image_path),
                        '@id' =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $d),
                        '@type' =>  'dctypes:Image',
                        'format' =>  'image/jpeg',
                        'service' =>  {
                            '@context' =>  'http://iiif.io/api/image/3/context.json',
                            '@id' =>  sprintf('%s/%s', $config->{iiif_server}, $d),
                            # sprintf('%s/%s/full/full/0/default.jpg', $config->{iiif_server}, $d),   
                            'profile' =>  'level2'
                        },
                        'height' =>  2805,
                        'width' =>  1760
                    },
                    'on' =>  sprintf('http://%s', $ug->to_string($ug->create())),
                    }
                ],
                'related' =>  ''
        };
        push (@canvases, $canvas_template);
        $count++;
    }

    $manifest_template =
        {
        '@context' =>  'http://iiif.io/api/presentation/2/context.json',
        '@id' =>  'http://ddeba432-e420-482e-a8bd-1f828d6d7a3e',
        '@type' =>  'sc:Manifest',
        'label' => $record_data->{label},
        'thumbnail' =>  {
            '@id' => "http://10.0.0.200:8182/iiif/2/roseggern/full/200,/0/default.jpg",
            'service' => {
                '@context' =>  "http://iiif.io/api/image/2/context.json",
                'profile' => "http://iiif.io/api/image/2/level2.json",
                '@id' =>  "http://10.0.0.200:8182/iiif/2/roseggern"            }
        },
        'metadata' =>  [
            {
            'label' => [
                {
                '@value' => 'Id',
                '@language' => 'en'
                },
                {
                '@value' => 'Id',
                '@language' => 'ger'
                }
            ],
            'value' => 'wrz17030823'		
            # Dürfte sich um die Quelle der Dateien handeln, also bei uns der Ordnername ??? -> dann wäre es z.B. KLZ-2020-10-25 ????
            },
            {
            'label' => [
                {
                '@value' => 'Title',
                '@language' => 'en'
                },
                {
                '@value' => 'Titel',
                '@language' => 'ger'
                }
            ],
            'value' => 'Wiener Zeitung'	#XXX		245a
            },
            {
            'label' => [			## XXX zusätzliche Metadaten
                {
                '@value' => 'Personal Name',
                '@language' => 'en'
                },
                {
                '@value' => 'Personenname',
                '@language' => 'ger'
                }
            ],
            'value' => 'WERT'	        #XXX		100a
            },
            {

            'label' => [
                {
                '@value' => 'Type',
                '@language' => 'en'
                },
                {
                '@value' => 'Typ',
                '@language' => 'ger'
                }
            ],
            'value' => 'newspaper'		#XXX	942c
            },
            {
            'label' => [
                {
                '@value' => 'Place of Publications',
                '@language' => 'en'
                },
                {
                '@value' => 'Erscheinungsort',
                '@language' => 'ger'
                }
            ],
            'value' => 'XXX 264a'
            },
            {
            'label' => [
                {
                '@value' => 'Date Issued',
                '@language' => 'en'
                },
                {
                '@value' => 'Erscheinungsdatum',
                '@language' => 'ger'
                }
            ],
            'value' => '1703-08-23'			#XXX 264c
            },
            {
            'label' => [			## zusätzliche Metadaten
                    {
                    '@value' => 'Extent ',
                    '@language' => 'en'
                    },
                    {
                    '@value' => 'Umfang',
                    '@language' => 'ger'
                    }
                ],
                'value' => 'WERT '	## XXX		300a
            },
            {
            'label' => [			## zusätzliche Metadaten
                    {
                    '@value' => 'Signatur ',
                    '@language' => 'en'
                    },
                    {
                    '@value' => 'Signatur',
                    '@language' => 'ger'
                    }
                ],
                'value' => 'WERT '	## XXX		952o
            },            
            {
            'label' => [
                {
                '@value' => 'Disseminator',
                '@language' => 'en'
                },
                {
                '@value' => 'Anbieter',
                '@language' => 'ger'
                }
            ],
            'value' => 'RaraBib'
            },
            {
            'label' => [
                {
                '@value' => 'Languages',
                '@language' => 'en'
                },
                {
                '@value' => 'Sprachen',
                '@language' => 'ger'
                }
            ],
            'value' => 'ger'		##			041a – aber ansonsten Fixert: ger
            }
  ],
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
        'sequences' =>  [
            {
            '@id' =>  'http://f617846c-3c25-4fa8-bf18-ab91ebf35c3d',
            '@type' =>  'sc:Sequence',
            'label' =>  [
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
