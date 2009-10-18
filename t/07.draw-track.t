use strict;

use Geo::Graph qw/:all/;
use Test::More tests => 5;
use vars qw/ $I /;

$ENV{GEO_GRAPH_CACHE_PATH} = "/home/aki/projects/cache";

require_ok('Geo::Graph::Canvas');

my $geo;
eval { $geo = Geo::Graph->new };
ok(!$@,"Loaded Geo::Graph okay <$@>");

eval{ $geo->load('t/sample1.gpx') };
ok(!$@,"Loaded Sample track okay <$@>");

# now we recolour the line based upon how fast we were going
my $overlay           = $geo->overlay_get(0);
my $overlay_primitive = $overlay->overlay_primitive_get(0);
my $dataset_primitive = $overlay_primitive->dataset_primitive;
$dataset_primitive->filter(FILTER_CLEAN => { speed_max => 10 });

# Let's just assume that the distribution is normalized (in actuality,
# it's bimodal but we'll ignore that here)
my $m = $dataset_primitive->{_metadata};
my $d = $m->{velocity_max} - $m->{velocity_min};

# Figure out what the colour buckets should be
$dataset_primitive->iterator_reset;
my @velocity_list;
while (  my $coord = $dataset_primitive->iterator_next ) {
    my $metadata = $coord->[REC_METADATA];
    push @velocity_list, $metadata->{velocity} || 0;
}
@velocity_list = sort { $a <=> $b } @velocity_list;
my $sub_buf = q`sub { my ( $i ) = @_; `;
my $e = @velocity_list / 241;
for my $i ( 0..239 ) {
    my $j = int($i * $e);
    my $s = $velocity_list[$j];
    my $c = $i / 241;
    $sub_buf .= $i > 0 ? "elsif ( \$i <= $s ) {"
                       : "if ( \$i <= $s ) {";
    $sub_buf .= "return $c; }\n";
}
$sub_buf .= q` return 1 }`;
my $sub_fn = eval $sub_buf;

$overlay_primitive->thickness(5);
$overlay_primitive->colour(sub{
    my ( $prev_entry, $entry, $segment_colour ) = @_;

# We want a logarithmic increase
    my $cv = $sub_fn->( $entry->[REC_METADATA]{velocity} );
    my $r = int( 255 *  $cv );
    my $b = int( 255 * ( 1 -  $cv ) );

    return [$r,0,$b];
});

my $png;
eval{ $png = $geo->png };
ok(!$@,"PNG creation ran okay <$@>");
ok( ($png and !ref($png)), "PNG created" );

open F, ">/tmp/out.png";
binmode F;
print F $png;
close F;

