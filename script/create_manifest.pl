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

my $config = {
    server => 'http://10.0.0.200:8182/iiif/3',
    datadir => '',
};

my $start_dir = '/home/mh/koha-devel/cantaloupe/data';
my $dir_sep = '%2F';

# Allowed image extensions
my @image_extensions = qw(jpg jpeg png gif);

# Function to check if a file is an image
sub is_image {
    my $file = shift;
    my ($ext) = $file =~ /\.([^.]+)$/;
    return grep { lc($ext) eq $_ } @image_extensions;
}

# Function to process a directory
sub process_directory {
    my $dir = shift;
    say $dir;
    opendir(my $dh, $dir) or die "Could not open '$dir' for reading: $!\n";
    my @files = readdir($dh);
    closedir($dh);

    my @image_files = grep { -f $_ && is_image($_) } map { sprintf("%s/%s", $dir, $_) } sort @files;
    return unless @image_files;
    my @images;
    for my $image (@image_files) {
        $image =~ s/^\Q$start_dir\/\E//;
        $image =~ s/\//$dir_sep/g;
        push (@images, $image);
    }
    
    print Dumper \@images;
   
    my $record_data = {
        image_data => \@images,        
        label => $dir,
    };

    my $manifest = Koha::Plugin::HKS3::IIIF::create_iiif_manifest($record_data, $config);
    my $manifest_file = "$dir/manifest.json";
    write_file($manifest_file, encode_json($manifest));    
    print "Manifest created for $dir\n";
}

# Crawl the filesystem and process directories
find({
    wanted => sub {
        return unless -d $_;
        process_directory($File::Find::name);
    },
    no_chdir => 1
}, $start_dir);

print "Completed generating manifests.\n";



__END__
create a perl script which takes a (sub)directory as an input parameter, 
and creates a IIIF manifest file with all the media files in the directory (sorted lexically), 
the default iiif parameters are read from a json files (provied via command line) and 
may be (partly) overrifden with another json files also provided via command line