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
    my $biblionumber = shift;
my $html = <<'EOT';
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="theme-color" content="#000000">
    <title>Mirador</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Roboto:300,400,500">
    <script src="https://unpkg.com/mirador@latest/dist/mirador.min.js" crossorigin=""></script>
  </head>
  <body>
    <div id="mirador" style="position: absolute; top: 0; bottom: 0; left: 0; right: 0;"></div>    
    <script type="text/javascript">
    var miradorInstance = Mirador.viewer({
        id: 'mirador',
        windows: [{
          manifestId: '/api/v1/contrib/hks3_mirador/iiifmanifest?biblionumber=XBIBX',
          thumbnailNavigationPosition: 'far-bottom'
        }],
        window: {
          allowClose: false,
          allowFullscreen: true,
        },
        workspaceControlPanel: {
          // per docs: Useful if you want to lock the viewer down to only the configured manifests.
          // the only valuable thing we lose is the fullscreen button, so we enable it elsewhere
          enabled: false,
        },
      });
    </script>
  </body>
</html>
EOT

$html =~ s/XBIBX/$biblionumber/g;
return $html;
}

1;
