use strict;

use Geo::Graph qw/:all/;
use Test::More tests => 4;

$ENV{GEO_GRAPH_CACHE_PATH} = "/home/aki/projects/cache";

my $geo;
eval { $geo = Geo::Graph->new };
ok(!$@,"Loaded Geo::Graph okay <$@>");

eval{ $geo->load('t/sample1.gpx') };
ok(!$@,"Loaded Sample track okay <$@>");

my $png;
eval{ $png = $geo->png };
ok(!$@,"PNG creation ran okay <$@>");
ok( ($png and !ref($png)), "PNG created" );

