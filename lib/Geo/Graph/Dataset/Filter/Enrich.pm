package Geo::Graph::Dataset::Filter::Enrich;

use strict;
use Geo::Graph qw/ :constants/;
use Geo::Graph::Utils;
use Geo::Graph::Dataset::Filter
    ISA => 'Geo::Graph::Dataset::Filter',
    GEO_ATTRIBS => {
    };

# This filter will simply enrich the dataset with more information
# eg. distance between points, velocity, acceleration, etc

sub filter {
# --------------------------------------------------
# Execute the filter on a sequence of data points
#
    my ( $self, $ds_primitive ) = @_;

# Now figure out the distance between each of the data points
# We make one very imporant assumption, that the time reported
# for each point in the track is either correct or very near 
# correct
    $ds_primitive->iterator_reset;
    my $coord_prev     = $ds_primitive->iterator_next;
    my $time_total     = 0;
    my $distance_total = 0;
    while ( my $coord = $ds_primitive->iterator_next ) {
        my $distance = distance($coord_prev,$coord);
        my $tvector  = $coord->[REC_TIMESTAMP] - $coord_prev->[REC_TIMESTAMP];
        my $velocity = $tvector > 0 ? $distance / $tvector : 0;
        my $accel    = $velocity - ($coord_prev->[REC_METADATA]{velocity}||0);

# FIXME probably not the most useful way of doing things. We should probably use a
# writer or something as this assumes too much about the underlying data storage
# mechanism
        my $metadata = $coord->[REC_METADATA];
        $metadata->{distance_since_previous} = $distance;
        $metadata->{distance} = $distance_total += $distance;
        $metadata->{runtime_since_previous} = $tvector;
        $metadata->{runtime}  = $time_total += $tvector;
        $metadata->{velocity} = $velocity;
        $metadata->{accel}    = $accel;

        $coord_prev = $coord;
    };

    return $ds_primitive;
}

1;
