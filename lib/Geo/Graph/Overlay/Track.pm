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

1;
