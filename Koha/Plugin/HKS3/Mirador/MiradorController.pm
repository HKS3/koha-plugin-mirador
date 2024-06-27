package Koha::Plugin::HKS3::Mirador::MiradorController;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';

use Koha::Biblios;
use MARC::File::XML ( DefaultEncoding => 'utf8' );
use Koha::Plugin::HKS3::Mirador qw/create_iiif_manifest/;



sub get {
    my $c = shift->openapi->valid_input or return;
    my $biblionumber = $c->validation->param('biblionumber');
    
    my $manifest = create_iiif_manifest($biblionumber);
    return $c->render( status => 404) unless $manifest;
    return $c->render( status => 200, openapi => $manifest);
}


1;
