use Modern::Perl;

use C4::Biblio;
use C4::Context;
use Koha::Biblios;

my $dbh = C4::Context->dbh;
for my $subfield (qw(2 a d)) {
    $dbh->do(q(update marc_subfield_structure set hidden = 0 where tagfield = '856' and tagsubfield = ? and frameworkcode = 'BKS';), {}, $subfield);
}

# format: [$biblionumber, [fields: [args for MARC::Field]]]
my @testdata = (
    # 191: static manifest
    [191, [ ['856','','','2' => 'IIIF-Manifest', 'd' => 'manifest.json'] ] ],
    # 5: single image
    [5,   [ ['856','','','2' => 'IIIF', 'd' => '0001.jpg'] ] ],
    # 11: two images
    [11,  [ ['856','','','2' => 'IIIF', 'd' => '0001.jpg'], ['856','','','2' => 'IIIF', 'd' => '0002.png'] ] ],
);

for (@testdata) {
    my ($biblionumber, $new_fields) = @$_;
    my $biblio = Koha::Biblios->find($biblionumber);
    my $framework = $biblio->frameworkcode;
    my $record = $biblio->metadata->record;

    my @fields = map { MARC::Field->new(@$_) } @$new_fields;

    $record->append_fields(@fields);
    C4::Biblio::ModBiblio($record, $biblionumber, $framework);
}
