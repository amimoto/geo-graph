package Geo::Graph::Dataset;

use strict;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Dataset;
use Geo::Graph::Base,
    ISA => 'Geo::Graph::Dataset',
    GEO_ATTRIBS => {
        datasets       => [],
        dataset_selected => undef,
    };

# Handle any combination of tracks/waypoints/shapes

sub dataset_insert {
# --------------------------------------------------
# Insert a new dataset
#
    my $self = shift;
    return push @{$self->{datasets}}, @_;
}

sub dataset_splice {
# --------------------------------------------------
# Does the same thing as perl's splice on the
# dataset
#
    my $self = shift;
    my @removed = splice @{$self)->{datasets}}, @_;

# Ensure we're not actively pointing to a dead dataset if we've pruned it
    if ( $self->{dataset_selected} ) {
        for ( @removed ) {
            next unless $_ eq $self->{dataset_selected};
            $self->{dataset_selected} = undef;
            last;
        }
    }

# Now respond to the user as they expected things to work
    return wantarray ? @removed : 0+@removed;
}

sub dataset_select {
# --------------------------------------------------
# Select the active dataset
#
    my ( $self, $i ) = @_;
    return $self->{dataset_selected} = $self->{dataset}[$i];
}

sub dataset_range {
# --------------------------------------------------
    my ( $self ) = @_;
    return $self->{_range} if $self->{_range};

    my $datasets = $self->{datasets} or return;
    my @range = qw( 10000 10000 10000 -10000 -10000 -10000  );
    for my $dataset ( @$datasets ) {

        my $dataset_range = $dataset->range;

# Handle latitude range
        if ( $range[RANGE_MIN_LAT] > $dataset_range->[RANGE_MIN_LAT] ) {
            $range[RANGE_MIN_LAT] = $dataset_range->[RANGE_MIN_LAT];
        }
        if ( $range[RANGE_MAX_LAT] < $dataset_range->[RANGE_MAX_LAT] ) {
            $range[RANGE_MAX_LAT] = $dataset_range->[RANGE_MAX_LAT];
        }

# Handle longitude range
        if ( $range[RANGE_MIN_LON] > $dataset_range->[RANGE_MIN_LON] ) {
            $range[RANGE_MIN_LON] = $dataset_range->[RANGE_MIN_LON];
        }
        if ( $range[RANGE_MAX_LON] < $dataset_range->[RANGE_MAX_LON] ) {
            $range[RANGE_MAX_LON] = $dataset_range->[RANGE_MAX_LON];
        }

# Handle altitudinal range
        if ( $range[RANGE_MIN_ALT] > $dataset_range->[RANGE_MIN_ALT] ) {
            $range[RANGE_MIN_ALT] = $dataset_range->[RANGE_MIN_ALT];
        }
        if ( $range[RANGE_MAX_ALT] < $dataset_range->[RANGE_MAX_ALT] ) {
            $range[RANGE_MAX_ALT] = $dataset_range->[RANGE_MAX_ALT];
        }
    }

    return $self->{_range} ||= \@range;
}

1;

