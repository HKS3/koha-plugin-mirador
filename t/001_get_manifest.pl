#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Basename;
use JSON;
use Modern::Perl;
use File::Slurp;

use Data::Dumper;
use Getopt::Long;
use Path::Tiny;
use Koha::Plugin::HKS3::IIIF qw(create_iiif_manifest);
use Koha::Plugin::HKS3::Mirador::MiradorController;
use File::Basename;
use File::Spec;
use File::Path qw(make_path);
use FindBin;

my $config = {
    iiif_server => 'http://10.0.0.200:8182/iiif/3',
    image_dir => '/home/mh/cantaloupe/images',
    manifest_dir => '/var/www/html/mh/manifest',

};

my $filename = 'manifest.json';

my $file = File::Spec->catfile($FindBin::Bin, $filename);
my $manifest = read_file($file) or die "Could not open '$file': $!";

my $data = decode_json($manifest);

# Pretty-print the JSON
my $pretty_json = JSON->new->utf8->pretty->encode($data);

# Print nicely formatted JSON to console
print $pretty_json;

# print $manifest;


__END__
