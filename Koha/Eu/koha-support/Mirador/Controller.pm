package Koha::Plugin::Eu::KohaSupport::Mirador::Controller;

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

use Koha::Plugin::Eu::KohaSupport::Mirador;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

=head1 Koha::Plugin::Eu::KohaSupport::Mirador::Controller

A class implementing the controller code for Mirador requests

=head2 Class methods

=head3 method1

Method bla

=cut

sub bla {
    my $c = shift->openapi->valid_input or return;

    my $body = $c->req->body;

    return try {

        my $order_id = 1; # TODO, should call some method that does something :-D

        $c->render(
            status  => 200,
            openapi => {
                order_id => $order_id
            }
        );
    }
    catch {
        return $c->render(
            status  => 500,
            openapi => { error => "Something went wrong. Check the logs." }
        );
    };
}

our $VERSION = 1.0;
our $metadata = {
    name   => 'IIIF Viewer',
    author => 'Your Name',
    description => 'A plugin to serve IIIF data to viewers like Mirador',
    date_authored => '2024-05-14',
    date_updated => '2024-05-14',
    version => $VERSION,
};

sub new {
    my ($class, $args) = @_;
    my $self = $class->SUPER::new($args);
    return $self;
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

# Example method to create a IIIF manifest
sub create_iiif_manifest {
    my ($self, $biblio_id) = @_;
    
    # This is a simplified example. You should retrieve actual data from your Koha instance
    my $manifest = {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => "http://yourkohaurl/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::IIIFViewer&method=handle_iiif_manifest&biblio_id=$biblio_id",
        '@type' => 'sc:Manifest',
        'label' => "Example Manifest for Biblio $biblio_id",
        'sequences' => [
            {
                '@type' => 'sc:Sequence',
                'canvases' => [
                    {
                        '@id' => "http://yourkohaurl/iiif/canvas/$biblio_id",
                        '@type' => 'sc:Canvas',
                        'label' => "Page 1",
                        'height' => 1800,
                        'width' => 1200,
                        'images' => [
                            {
                                '@type' => 'oa:Annotation',
                                'motivation' => 'sc:painting',
                                'resource' => {
                                    '@id' => "http://yourkohaurl/iiif/image/$biblio_id",
                                    '@type' => 'dctypes:Image',
                                    'format' => 'image/jpeg',
                                    'height' => 1800,
                                    'width' => 1200,
                                },
                                'on' => "http://yourkohaurl/iiif/canvas/$biblio_id",
                            },
                        ],
                    },
                ],
            },
        ],
    };
    
    return $manifest;
}

1;



1;
