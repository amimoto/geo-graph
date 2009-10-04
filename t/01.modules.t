use strict;
use vars qw/ @TEST_MODULES /;

@TEST_MODULES = qw(
    Test::More
    GD
    Geo::Graph
    Geo::Graph::Base
    Geo::Graph::Canvas
    Geo::Graph::Dataset
    Geo::Graph::Dataset::Filter
    Geo::Graph::Dataset::Filter::Clean
    Geo::Graph::Dataset::Primitive
    Geo::Graph::Dataset::Primitive::Track
    Geo::Graph::Datasource
    Geo::Graph::Overlay
    Geo::Graph::Overlay::Primitive
);

require Test::More;
Test::More->import( tests => 0+@TEST_MODULES );

for my $module ( @TEST_MODULES ) {
    use_ok( $module );
}

