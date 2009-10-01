package Geo::Graph::Dataset::Filter::Simplify;

use strict;

# Attempt to reduce the number of points in the track to a size "n"
# I think this is using a similar method to gpsbabel's 'simplify' 
# command which removes points based upon how much error it introduces
# into the track.

sub filter {
# --------------------------------------------------
# Run the filter
#
    my ( $self, $opts ) = @_;
}

sub thin {
# --------------------------------------------------
# Request the system to remove data points based
# upon criteria including:
#
# 1. Minimum distance between points
# 2. Minimum time between points
# 3. Maximum number of points
#
# TODO: We are not considering vertical distance at the
# moment, which must be done. Good for people who fly 
# (eg. Superman, pigs, birds and uh, pilots)
#
    my ( $self, $mode, $value, $opts ) = @_;

    THIN_BY_DISTANCE eq $mode and do {
    };

    THIN_BY_TIME eq $mode and do {
    };

    THIN_TO_COUNT eq $mode and do {
    };

    return $self;
}




1;
