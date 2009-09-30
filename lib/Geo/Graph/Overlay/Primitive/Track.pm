package Geo::Graph::Overlay::Primitive::Track;

use strict;
use Geo::Graph::Overlay::Primitive
    ISA => 'Geo::Graph::Overlay::Primitive',
    GEO_ATTRIBS => {
        thickness => 2,
        colour    => [255,0,0], # by default we make the route red
        range     => undef,
    };

sub range {
# --------------------------------------------------
# Calculate the maximum boundaries that this track 
# fills (return lat/lon)
#
    my ( $self ) = @_;
    my $dataset = $self->{dataset_primitive} or return;
    return $self->{range} ||= $dataset->range;
}

sub canvas_draw {
# --------------------------------------------------
# Draw the tracks on the map
#
    my ( $self, $canvas_obj ) = @_;

    my $dataset = $self->{dataset_primitive} or return;

    $dataset->iterator_reset;
    my $prev_entry = $dataset->iterator_next;
    $canvas_obj->setThickness($self->{thickness}||2);
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

    return 1;
}

1;
