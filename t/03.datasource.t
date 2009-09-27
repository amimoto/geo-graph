use strict;

use Test::More qw( no_plan );

use Geo::Graph qw/ :constants /;
use Geo::Graph::Datasource;

# Now load an example track from the database
my $ds_gpx = Geo::Graph::Datasource->load('03.sample.gpx');

use Data::Dumper; die Dumper $ds_gpx;

