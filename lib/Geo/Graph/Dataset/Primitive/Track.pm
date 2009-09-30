package Geo::Graph::Dataset::Primitive::Track;

use strict;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Dataset::Primitive;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Dataset::Primitive',
    GEO_ATTRIBS => {
        overlay_hint => OVERLAY_TRACK,
    };

# Handle a single track or series of waypoints in a single path

1;

