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
use C4::Biblio;
use C4::Context;
use File::Slurp;
use Koha::Biblios;
use Mojo::JSON qw(decode_json);
use URI::Encode  qw(uri_encode);
use Koha::Plugin::HKS3::IIIF qw(create_iiif_manifest);

=head1 Koha::Plugin::HKS3::Mirador

A class implementing the controller code for Mirador requests

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

my $config; # needs to be global so that the static get_manifest_from_koha() can read it

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    my $self = $class->SUPER::new($args);

    $self->{cgi} = CGI->new();
    $self->load_config();
    
    return $self;
}

sub load_config {
    my $self = shift;

    $config->{iiif_server}     = $self->retrieve_data('iiif_server');
    $config->{manifest_server} = $self->retrieve_data('manifest_server');

    $config->{fields} = {
        title         => ['245', 'a'],
        personal_name => ['100', 'a'],
        type          => ['942', 'c'],
        place_of_publications => ['264', 'a'],
        date_issued => ['264', 'c' ],
        extent      => ['300', 'a' ],
        signature   => ['952', 'o' ],
        language => ['041', 'a'],
    };

    $config->{field_defaults} = {
        language => 'ger',
    };
}

sub api_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub configure {
    my ( $self, $args ) = @_; 
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) { 
        my $template = $self->get_template({ file => 'configure.tt' }); 

        ## Grab the values we already have for our settings, if any exist
        $template->param(
            iiif_server       => $self->retrieve_data('iiif_server'),    
            manifest_server   => $self->retrieve_data('manifest_server'),
        );

        $self->output_html( $template->output() );
    }   
    else {
        $self->store_data(
            {
                iiif_server         => $cgi->param('iiif_server'),
                manifest_server     => $cgi->param('manifest_server'),
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
        $self->load_config();

        $self->go_home();
    }   
}

sub api_namespace {
    my ( $self ) = @_;

    return 'hks3_mirador';
}

# either get manifest from url or from file
sub get_manifest {
    my $field = shift;

    my $return;
    if ($field->subfield('d') && ! $field->subfield('a') ) {
        # path, no hostname
        my $filename = $field->subfield('d');           
        my $file = File::Spec->catfile($FindBin::Bin, $filename);
        $return = read_file($file) or die "Could not open '$file': $!";      
    } elsif ($field->subfield('a')) {  
        # hostname, possibly no path?
        my $path = uri_encode($field->subfield('d'));
        my $url = sprintf("%s/%s", $config->{manifest_server}, $path);
    
        my $http = HTTP::Tiny->new;
        warn "Will query $url for manifest";
        my $response = $http->get($url);
        

        if ($response->{success}) {
            $return = decode_json($response->{content});   
        }
    }


    return $return;
}

sub get_manifest_from_koha {
    my ($biblionumber) = @_;
    my $biblio = Koha::Biblios->find($biblionumber);
    my $record = $biblio->metadata->record;
    
    my @data = $record->field('856');
    return unless @data;

    my $get_subfield_for = sub {
        my $key = shift;
        my ($field, $subfield) = $config->{fields}{$key}->@*;
        my $marc_field = $record->field($field);
        return $marc_field ? $marc_field->subfield($subfield) : undef;
    };

    my %metadata;
    for my $key (keys $config->{fields}->%*) {
        $metadata{$key} = $get_subfield_for->($key) // $config->{field_defaults}{$key};
    }

    my @manifest_fields = grep { ($_->subfield('2') // '') eq 'IIIF-Manifest' } @data;
    if (@manifest_fields) {
        # Backcompat with the old code: only use the first field. Later figure out how to handle this sensibly.
        my $field = $manifest_fields[0];

        warn "Using preconfigured manifest for $biblionumber";
        my $manifest = get_manifest($field);
        $manifest->{label} = $metadata{label};
        # $manifest->{metadata} = [ { value =>  $record->field('100')->subfield('a') } ];
        # check if exist
        return $manifest;
    }

    warn "Generating manifest for $biblionumber";
    my @iiif_fields = grep { ($_->subfield('2') // '') eq 'IIIF' } @data;

    my @paths = map { $_->subfield('d') } @iiif_fields;

    return Koha::Plugin::HKS3::IIIF::create_iiif_manifest({
        %metadata,
        image_data => \@paths,
    }, $config);
}    


sub opac_head {
    my ( $self ) = @_;

    return unless CGI->new->script_name eq '/opac/opac-detail.pl';

    return q|<script src="https://unpkg.com/mirador@latest/dist/mirador.min.js" crossorigin=""></script>|;
}


sub opac_js {
    my ( $self ) = @_;

    return unless CGI->new->script_name eq '/opac/opac-detail.pl';

    my $payload = $self->mbf_read('opac.js');
    return "<script> $payload </script>";
}

1;
