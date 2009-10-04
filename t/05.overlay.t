use strict;

use Test::More qw( no_plan );

use Geo::Graph qw/ :constants /;
use Geo::Graph::Overlay;

# Now load an example gpx track 
my $ovl = eval { Geo::Graph::Overlay->load('t/sample1.gpx') };
ok( $ovl, "Loaded okay! <$@>" );

