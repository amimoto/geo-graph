use strict;

use Test::More qw( no_plan );

use Geo::Graph qw/ :constants /;
use Geo::Graph::Dataset;

# Create a blank Dataset object
my $ds = Geo::Graph::Dataset->new;
ok( $ds, "Created a blank dataset" );

# Create a blank Dataeset + Track layout
my $track_ds = Geo::Graph::Dataset->new(
                    DATASET_TRACK => []
                );


