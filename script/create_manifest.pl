#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use Modern::Perl;

use Koha::Plugin::HKS3::IIIF;

use File::Basename;
use File::Find;
use File::Slurp;
use File::Spec;
use File::Path qw(make_path);

use Getopt::Long qw( GetOptions );
use URI::Encode qw(uri_encode);
use Try::Tiny;

my $config = {}; 

GetOptions(
    'iiif_server=s'   => \$config->{iiif_server},
    'image_dir=s'     => \$config->{image_dir},
    'manifest_dir=s'  => \$config->{manifest_dir},
) or die "Error in command line arguments\n";

if (scalar(grep { $_ } values %$config) != 3) {
    die "Usage: $0 --iiif_server <URL> --image_dir <directory> --manifest_dir <directory>\n";
}

my $start_dir = $config->{image_dir};
my $dir_sep = '%2F';

sub is_image {
    my $file = shift;
    my ($ext) = $file =~ /\.([^.]+)$/;
    return grep { lc($ext) eq $_ } qw(jpg jpeg png gif pdf);
}

sub match_transcripts {
    my @paths = @_;
    my %pathmap = map { ($_ => 1) } @paths;

    my @groups;

    for my $path (@paths) {
        # does it have a transcript?
        if ($pathmap{"9$path"}) {
            push @groups, [$path, "9$path"];
        }
        # is it a transcript?
        elsif ($path =~ /^9/ and $pathmap{$path =~ s/^9//r}) {
            # ignore
        }
        else {
            push @groups, $path;
        }
    }

    return \@groups;
}

# Function to process a directory
sub process_directory {
    my $dir = shift;
    say "Processing $dir...";
    
    my $relative_path = File::Spec->abs2rel($dir, $start_dir);

    opendir(my $dh, $dir) or die "Could not open '$dir' for reading: $!\n";
    my @files = readdir($dh);
    closedir($dh);

    my @image_files = grep { -f $_ && is_image($_) } map { sprintf("%s/%s", $dir, $_) } sort @files;
    return unless @image_files;

    my @not_pdfs;
    for my $image_path (@image_files) {
        my $filename = basename($image_path);
        my $encoded_path = uri_encode($image_path =~ s/^\Q$start_dir\/\E//r, { encode_reserved => 1 });
		
        if ($filename =~ /\.pdf$/i) {
            my @pdfs = Koha::Plugin::HKS3::IIIF::create_paths_from_pdf($image_path, $encoded_path, $config);
            store_manifest(\@pdfs, $encoded_path, $relative_path, $filename.'.json');
        } else {
            push @not_pdfs, $encoded_path;
        }
    }
    
    try {
        store_manifest(match_transcripts(@not_pdfs), $dir, $relative_path) if @not_pdfs;
    } catch {
        warn "Failed to write manifest for $relative_path: $_";
    };
}

# Crawl the filesystem and process directories
find({
    wanted => sub {
        return unless -d $_;
        process_directory($File::Find::name);
    },
    no_chdir => 1
}, $start_dir);

say "Completed generating manifests.";

sub store_manifest {
    my ($images, $label, $relative_path, $manifest_filename) = @_;
    $manifest_filename //= 'manifest.json';

    my $record_data = {
        image_data => $images,
        label => $label,
    };

    my $target_dir = File::Spec->catfile($config->{manifest_dir}, $relative_path);
    unless (-d $target_dir) {
        make_path($target_dir) or die "Failed to create directory: $!";
    }
    my $manifest_file = File::Spec->catfile($target_dir, $manifest_filename);
    my @partial_manifest = Koha::Plugin::HKS3::IIIF::create_canvases($images, $config);
    write_file($manifest_file, encode_json(\@partial_manifest));
    say "Manifest created: $manifest_file";
}


__END__
create a perl script which takes a (sub)directory as an input parameter, 
and creates a IIIF manifest file with all the media files in the directory (sorted lexically), 
the default iiif parameters are read from a json files (provied via command line) and 
may be (partly) overrifden with another json files also provided  ivia command line
