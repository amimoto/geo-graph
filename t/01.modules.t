use strict;
use vars qw/ @TEST_MODULES /;

@TEST_MODULES = qw(
    Test::More
    GD
    Geo::Graph
    Geo::Graph::Base
    Geo::Graph::Canvas
    Geo::Graph::Overlay
    Geo::Graph::Overlay::Track
    Geo::Graph::Dataset
    Geo::Graph::Dataset::GPX
    Geo::Graph::Mercator
);

require Test::More;
Test::More->import( tests => 0+@TEST_MODULES );

for my $module ( @TEST_MODULES ) {
    use_ok( $module );
}
