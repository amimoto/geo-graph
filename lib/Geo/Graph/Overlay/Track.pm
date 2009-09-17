package Geo::Graph::Overlay::Track;

use strict;
use Geo::Graph::Overlay;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Overlay',
    GEO_ATTRIBS => {
        thickness => 5,
        colour    => [255,0,0], # by default we make the route red
        range     => undef,
    };

sub range {
# --------------------------------------------------
# Calculate the maximum boundaries that this track 
# fills (return lat/lon)
#
    my ( $self ) = @_;
    my $dataset = $self->{data} or return;
    return $self->{range} ||= $dataset->range;
}

sub canvas_draw {
# --------------------------------------------------
# Draw the tracks on the map
#
    my ( $self, $canvas_obj ) = @_;

    my $dataset = $self->{data} or return;

    $dataset->iterator_reset;
    my $prev_entry = $dataset->iterator_next;
    $canvas_obj->setThickness($self->{thickness}||5);
    my $rgb = $self->{colour};
    while ( my $entry = $dataset->iterator_next ) {
        my $segment_colour = ref $rgb eq 'CODE' ? $rgb->( $prev_entry, $entry, $canvas_obj ) : $rgb;
        $canvas_obj->line(
            $prev_entry,
            $entry,
            $segment_colour
        );
        $prev_entry = $entry;
    }

    my $range_center = Geo::Graph->range_center($self->range);
    $canvas_obj->circle( $range_center, 6, [255,0,0] );

    return 1;
}

1;
