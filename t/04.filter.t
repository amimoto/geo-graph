use strict;

use Test::More qw( no_plan );

use Geo::Graph qw/ :constants /;
use Geo::Graph::Datasource;

# Now load an example track from the database
my $ds = eval { Geo::Graph::Datasource->load('t/sample1.gpx') };

# Create the filter object
my $filter = eval { $ds->filter( FILTER_CLEAN ) };
ok(!$@,"ran filter $@");

# Now filter the results


