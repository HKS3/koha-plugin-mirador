use Cwd 'abs_path';

my $file = '/opt/cantaloupe/data/DSR';

# Check if the file is a symbolic link
if (-l $file) {
    # Get the absolute path of the link target
    my $target = abs_path($file);
    
    # Check if the target is a directory
    if (defined $target && -d $target) {
        print "$file is a symbolic link pointing to a directory.\n";
    } else {
        print "$file is a symbolic link, but it does not point to a directory.\n";
    }
} else {
    print "$file is not a symbolic link.\n";
}

