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
use File::Slurp;
use HTTP::Tiny;
use Koha::Plugin::HKS3::IIIF qw(create_iiif_manifest);
use Koha::Logger;

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

our @EXPORT    = qw(get_manifest_from_koha);

my $config = {
    iiif_server => 'http://10.0.0.200:8182/iiif/3',
    manifest_server => 'http://10.0.0.200/mh/manifest',
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

sub get_manifest_from_koha {
    my ($biblionumber) = @_;
    my $biblio = Koha::Biblios->find($biblionumber);
    my $record       = $biblio->metadata->record;
    
    my @data = $record->field('856');
    
    return undef unless @data;
    foreach my $field (@data) {
    #my $field = $data[0];
        if ($field->subfield('2') && $data[0]->subfield('2') eq 'IIIF-Manifest')  {
            # my $url = 'http://10.0.0.200/mh/manifest/A/B/roseggern/manifest.json';
            my $url = sprintf("%s/%s", $config->{manifest_server}, $field->subfield('d'));
            my $http = HTTP::Tiny->new;
            my $response = $http->get($url);
            if ($response->{success}) {    
                return decode_json($response->{content});            
            } else {
                return undef;
            }
        }

        return undef unless $field->subfield('2') && $field->subfield('2') eq 'IIIF';
        
        warn("found IIIF");
        my @f856 = map { $_->subfield('d') } $field;
        my $record_data = {
            image_data => \@f856,        
            label => $record->field('245')->subfield('a'),
        };
        return Koha::Plugin::HKS3::IIIF::create_iiif_manifest($record_data, $config);
    }
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

