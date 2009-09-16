package Geo::Graph::Overlay::Track;

use strict;
use vars qw/ @ISA /;
use Geo::Graph::Overlay;
@ISA = 'Geo::Graph::Overlay';

sub track {
# --------------------------------------------------
}

sub range {
# --------------------------------------------------
# Calculate the maximum boundaries that this track 
# fills (return lat/lon)
#
    my ( $self ) = @_;
    my $dataset = $self->{data} or return;
    return $dataset->range;
}

sub canvas_draw {
# --------------------------------------------------
# Draw the tracks on the map
#
    my ( $self, $canvas_obj ) = @_;

    my $dataset = $self->{data} or return;

    $dataset->iterator_reset;
    my $prev_entry = $dataset->iterator_next;
    $canvas_obj->setThickness(5);
    while ( my $entry = $dataset->iterator_next ) {
        $canvas_obj->line(
            $prev_entry,
            $entry
        );
        $prev_entry = $entry;
    }
    
    return 1;
}

1;
