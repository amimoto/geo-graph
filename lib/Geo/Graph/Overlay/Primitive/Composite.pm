package Geo::Graph::Overlay::Composite;

use strict;
use Geo::Graph::Overlay;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Overlay',
    GEO_ATTRIBS => {
        overlays => [],
    };

sub overlay_add {
# --------------------------------------------------
# Inserts an overlay into the current stack
#
    my ( $self, $overlay ) = @_;
    push @{$self->{overlays}}, $overlay;
    return 0+@{$self->{overlays}};
}

sub range {
# --------------------------------------------------
# Calculates the full range based upon the all the 
# sub-overlays
#
    my ( $self ) = @_;
    my @range = qw( 10000 10000 10000 -10000 -10000 -10000  );
    for my $overlay ( @{$self->{overlays}||[]}) {
        my $overlay_range = $overlay->range;

# Handle latitude range
        if ( $range[RANGE_MIN_LAT] > $overlay_range->[RANGE_MIN_LATITUDE] ) {
            $range[RANGE_MIN_LAT] = $overlay_range->[RANGE_MIN_LATITUDE];
        }
        if ( $range[RANGE_MAX_LAT] < $overlay_range->[RANGE_MAX_LATITUDE] ) {
            $range[RANGE_MAX_LAT] = $overlay_range->[RANGE_MAX_LATITUDE];
        }

# Handle longitude range
        if ( $range[RANGE_MIN_LON] > $overlay_range->[RANGE_MIN_LONGITUDE] ) {
            $range[RANGE_MIN_LON] = $overlay_range->[RANGE_MIN_LONGITUDE];
        }
        if ( $range[RANGE_MAX_LON] < $overlay_range->[RANGE_MAX_LONGITUDE] ) {
            $range[RANGE_MAX_LON] = $overlay_range->[RANGE_MAX_LONGITUDE];
        }

# Handle altitudinal range
        if ( $range[RANGE_MIN_ALT] > $overlay_range->[RANGE_MIN_ALT] ) {
            $range[RANGE_MIN_ALT] = $overlay_range->[RANGE_MIN_ALT];
        }
        if ( $range[RANGE_MAX_ALT] < $overlay_range->[RANGE_MAX_ALT] ) {
            $range[RANGE_MAX_ALT] = $overlay_range->[RANGE_MAX_ALT];
        }
    }

    return \@range;
}

sub canvas_draw {
# --------------------------------------------------
# Draws all the sub-overlays onto the canvas
#
    my ( $self, $canvas_obj ) = @_;
    for my $overlay ( @{$self->{overlays}||[]}) {
        $overlay->canvas_draw($canvas_obj);
    }
    return $canvas_obj;
}

1;
