package Koha::Plugin::HKS3::Mirador::MiradorController;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';

use Koha::Biblios;
use MARC::File::XML ( DefaultEncoding => 'utf8' );
use Koha::Plugin::HKS3::Mirador qw/get_manifest_from_koha/;



sub get {
    my $c = shift->openapi->valid_input or return;
    my $biblionumber = $c->validation->param('biblionumber');
    my $viewer = $c->validation->param('viewer');

    return $c->render(status => 200, text => viewer($biblionumber)) if $viewer;

    my $manifest = get_manifest_from_koha($biblionumber);
    return $c->render( status => 404, openapi => 
      {'error' => '404', 'no IIIF data found for biblionumber' => $biblionumber}) unless $manifest;
    return $c->render( status => 200, openapi => $manifest);
}

sub viewer {
    my ($biblionumber) = @_;
    my $html = <<'EOT';
    <div id="mirador""></div>
    <script type="module" src="/api/v1/contrib/hks3_mirador/static/mirador.js"></script>
    <script type="module">
        import installMirador from "./static/mirador.js";

        installMirador(
            'mirador', 
            '/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=XBIBX',
            document.querySelector('html').getAttribute('lang'),
        );
    </script>
EOT

    $html =~ s/XBIBX/$biblionumber/g;
    return $html;
}

1;
