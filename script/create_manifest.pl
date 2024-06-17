
use Modern::Perl;


use Data::Dumper;
use Text::CSV;
use Getopt::Long;
use Path::Tiny;


__END__
create a perl script which takes a (sub)directory as an input parameter, 
and creates a IIIF manifest file with all the media files in the directory (sorted lexically), 
the default iiif parameters are read from a json files (provied via command line) and 
may be (partly) overrifden with another json files also provided via command line