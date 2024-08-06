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

our @EXPORT = qw(create_iiif_manifest);

sub create_iiif_manifest {
    my ($record_data, $config) = @_;
    
 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg/full/full/0/default.jpg',
 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg',
    my $ug = Data::UUID->new;
    my @canvases;
    for my $d (@{$record_data->{image_data}}) {
        
        my $canvas_template = {
                '@id' =>  sprintf('http://%s', $ug->to_string($ug->create())),
                '@type' =>  'sc:Canvas',
                'label' =>  'cantaloupe',
                'height' =>  164,
                'width' =>  308,
                'images' =>  [
                    {
                    '@context' =>  'http://iiif.io/api/presentation/2/context.json',
                    '@id' =>  sprintf('http://%s', $ug->to_string($ug->create())),
                    '@type' =>  'oa:Annotation',
                    'motivation' =>  'sc:painting',
                    'resource' =>  {
                        # '@id' =>  sprintf('%s/%s/full/full/0/default.jpg', $config->{server}, $image_path),
                        '@type' =>  'dctypes:Image',
                        'format' =>  'image/jpeg',
                        'service' =>  {
                        '@context' =>  'http://iiif.io/api/image/3/context.json',
                        '@id' =>  sprintf('%s/%s', $config->{server}, $d),
                        'profile' =>  'level2'
                        },
                        'height' =>  164,
                        'width' =>  308
                    },
                    'on' =>  sprintf('http://%s', $ug->to_string($ug->create())),
                    }
                ],
                'related' =>  ''
        };
        push (@canvases, $canvas_template);
    }

    my $manifest =
        {
        '@context' =>  'http://iiif.io/api/presentation/2/context.json',
        '@id' =>  'http://ddeba432-e420-482e-a8bd-1f828d6d7a3e',
        '@type' =>  'sc:Manifest',
        'label' => $record_data->{label},
        'metadata' =>  [],
        'description' =>  [
            {
            '@value' =>  '[Click to edit description]',
            '@language' =>  'en'
            }
        ],
        'license' =>  'https://creativecommons.org/licenses/by/3.0/',
        'attribution' =>  '[Click to edit attribution]',
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

    

    return $manifest;
    }
