package Geo::Graph::Dataset::GPX;

use strict;
use vars qw/ $LOCAL_SELF @TS /;
use XML::Parser;
use Time::Local;
use Geo::Graph qw/:all/;
use constant {
        SIZEOF_f => length(pack("f",0)), # this is probably paranoia
        SIZEOF_L => length(pack("L",0)),
    };    
use Geo::Graph::Dataset
    ISA => 'Geo::Graph::Dataset',
    GEO_ATTRIBS => {
        entries                => 0,
        track_points           => '',
        track_points_elevation => '',
        track_points_time      => '',
    };

sub load {
# --------------------------------------------------
    my ( $self, $data ) = @_;
}

1;
