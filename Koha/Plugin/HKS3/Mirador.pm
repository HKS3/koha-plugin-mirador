package Koha::Plugin::HKS3::Mirador;

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

use base qw(Koha::Plugins::Base);
use Koha::Plugins::Tab;
use C4::Biblio;
use Koha::Biblios;
use Koha::Items;
use Cwd qw(abs_path);
use C4::Context;
use C4::Koha;
use Koha::AuthorisedValues;
use Data::UUID;

use Mojo::JSON qw(decode_json);

use Try::Tiny;

=head1 Koha::Plugin::HKS3::Mirador

A class implementing the controller code for Mirador requests

=head2 Class methods

=head3 method1


=cut

our $VERSION = 1.0;
our $metadata = {
    name   => 'IIIF Viewer',
    author => 'Mark Hofstetter',
    description => 'A plugin to serve IIIF data to viewers like Mirador',
    date_authored => '2024-05-14',
    date_updated => '2024-05-14',
    version => $VERSION,
};

our @EXPORT    = qw(create_iiif_manifest);

my $config = {
    server => 'http://10.0.0.200:8182/iiif/3',
    datadir => '',
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    $self->{cgi} = CGI->new();

    return $self;
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;

    return 'hks3_mirador';
}

# Define a method to handle the IIIF manifest request
sub handle_iiif_manifest {
    my ($self, $cgi) = @_;
    
    # Assuming you have a way to get the bibliographic data and create a IIIF manifest
    my $biblio_id = $cgi->param('biblio_id');
    my $manifest = $self->create_iiif_manifest($biblio_id);
    
    print $cgi->header(-type => 'application/json', -charset => 'utf-8');
    print encode_json($manifest);
}

sub create_iiif_manifest {
    my ($biblionumber) = @_;
    my $biblio = Koha::Biblios->find($biblionumber);
    my $record       = $biblio->metadata->record;
    
    my @data = $record->field('856');
    return undef unless @data;
    return undef unless $data[0]->subfield('2') &&  $data[0]->subfield('2') eq 'IIIF';
    my $ug = Data::UUID->new;


 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg/full/full/0/default.jpg',
 # '@id' =>  'http://10.0.0.200:8182/iiif/3/0001.jpg',
    my @canvases;
    for my $d (@data) {
        my $image_path = $d->subfield('d');            
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
                        '@id' =>  sprintf('%s/%s', $config->{server}, $image_path),
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
        'label' =>  $record->field('245')->subfield('a'),
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

sub opac_head {
    my ( $self ) = @_;

    return q|<script src="https://unpkg.com/mirador@latest/dist/mirador.min.js" crossorigin=""></script>|;
}


sub opac_js {
    my ( $self ) = @_;
    # XXX should check here if there is something to show
    my $payload = $self->mbf_read('opac.js');
    return "<script> $payload </script>";
}


sub opac_detail_xslt_variables {
    my ( $self, $params ) = @_;

    return { nice_message => 'We love Koha /' };
}

=head3 opac_results_xslt_variables

Plugin hook injecting variables to the OPAC results XSLT

=cut

sub opac_results_xslt_variables {
    my ( $self, $params ) = @_;

    return { nice_message => 'We love Koha /' };
}

1;

