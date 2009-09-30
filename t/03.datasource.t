use strict;

use Test::More qw( no_plan );

use Geo::Graph qw/ :constants /;
use Geo::Graph::Datasource;

# Now load an example track from the database
my $ds = eval { Geo::Graph::Datasource->load('t/03.sample.gpx') };
ok( $ds, "Loaded okay! <$@>" );

# Check the ranges
my $range = $ds->range;
