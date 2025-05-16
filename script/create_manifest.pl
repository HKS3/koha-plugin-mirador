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
use File::Basename;
use File::Spec;
use File::Path qw(make_path);


my $config_test = { 
    iiif_server => 'http://10.0.0.200:8182/iiif/2',
    image_dir => '/home/mh/cantaloupe/images',
    manifest_dir => '/var/www/html/mh/manifest',

};

my $config_stage = {
    iiif_server => 'https://lib-t-lx2.stlrg.gv.at/cantaloupe/iiif/2',
    # image_dir => '/mnt/IIF/Repositorium Digitalisate Online (RDO)',
    image_dir => '/mnt/IIF',
    manifest_dir => '/opt/cantaloupe/manifest',
};

my $config = $config_stage;

my $start_dir = $config->{image_dir};
my $dir_sep = '%2F';

# Allowed image extensions
my @image_extensions = qw(jpg jpeg png gif pdf );

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
    
# Remove base directory
    my $relative_path = File::Spec->abs2rel($dir, $start_dir);
    say $relative_path;

    opendir(my $dh, $dir) or die "Could not open '$dir' for reading: $!\n";
    my @files = readdir($dh);
    closedir($dh);

    my @image_files = grep { -f $_ && is_image($_) } map { sprintf("%s/%s", $dir, $_) } sort @files;
    return unless @image_files;
    my @images;

    for my $image (@image_files) {    
        my $fpi = $image;    
	my $filename = basename($image);
        $image =~ s/^\Q$start_dir\/\E//;                
        $image =~ s/\//$dir_sep/g;
		
	printf ("%s \n", $image);
		
   	# $filename =~ s/\s+/_/g; 
        if ($image =~ /\.pdf$/i) {
            my @pdfs = Koha::Plugin::HKS3::IIIF::create_iiif_manifest_from_pdf($fpi, $image, $config, $filename);
            store_manifest(\@pdfs, $image, $relative_path, $filename.'.json');
        } else {
            push (@images, $image);
        }
    }
    
    store_manifest(\@images, $dir, $relative_path);
    print Dumper \@images;
   
    
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

sub store_manifest {
    my ($images, $label, $relative_path, $manifest_filename) = @_;
    $manifest_filename //= 'manifest.json';

    my $record_data = {
        image_data => $images,        
        label => $label,
    };

    my $manifest = Koha::Plugin::HKS3::IIIF::create_iiif_manifest($record_data, $config);
    my $target_dir = File::Spec->catfile($config->{manifest_dir}, $relative_path);
    unless (-d $target_dir) {    
        make_path($target_dir) or die "Failed to create directory: $!";
    }
    my $manifest_file = File::Spec->catfile($target_dir, $manifest_filename);
    write_file($manifest_file, encode_json($manifest));    
    print "Manifest created for $relative_path\n";

}


__END__
create a perl script which takes a (sub)directory as an input parameter, 
and creates a IIIF manifest file with all the media files in the directory (sorted lexically), 
the default iiif parameters are read from a json files (provied via command line) and 
may be (partly) overrifden with another json files also provided  ivia command line
