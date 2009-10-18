package Geo::Graph::Dataset::Filter::Clean;

use strict;
use Geo::Graph qw/ :constants/;
use Geo::Graph::Utils;
use Geo::Graph::Dataset::Filter
    ISA => 'Geo::Graph::Dataset::Filter',
    GEO_ATTRIBS => {
        accel_max    => 30,      # 30      m/s^2
        speed_max    => 300_000, # 300,000 m/s (speed of sound)
        distance_max => 0,       # Maximum distance between any two points
        anchor_min   => 5,       # minimum 5 points in the anchor
        entries_min  => 10,      # don't bother unless 
    };

# This filter will remove datapoints in tracks that appear to have
# really large jumps and wiggles

sub filter {
# --------------------------------------------------
# Execute the filter on a sequence of data points
#
    my ( $self, $ds_primitive ) = @_;

# Get all velocity/accel/etc data down
    $ds_primitive->filter(FILTER_ENRICH);

=tag
# This code was used for debugging and to see velocity 
# distribution stats
# Find out what the max/min velocity values are
    $ds_primitive->iterator_reset;
    my $coord_first = $ds_primitive->iterator_next;
    my @velocity = ( 10000, -10000 );
    my @accel = ( 10000, -10000 );
    while ( my $coord = $ds_primitive->iterator_next ) {
        my $m = $coord->[REC_METADATA];
        my $v = $m->{velocity};
        $v < $velocity[0] and $velocity[0] = $v;
        $v > $velocity[1] and $velocity[1] = $v;
    }
    my $slots = 200;
    my $delta = $velocity[1] - $velocity[0];
    my $span  = $delta / $slots;
    $ds_primitive->iterator_reset;
    my @buckets = map {0} (1..$slots);
    while ( my $coord = $ds_primitive->iterator_next ) {
        my $m = $coord->[REC_METADATA];
        my $v = $m->{velocity};
        my $vd = $v - $velocity[0];
        my $b = int($vd/$span);
        $buckets[$b]++;
    }
    for my $i (0..$#buckets ) {
        warn "$i,$buckets[$i]\n";
    }
=cut

# We need to find stretches of sequence that will serve as the "anchor"
# We read all the self keys into variables reduce the cost on lookups 
# in the loop. We're going for fast here, mate :D
    my $valid_seq = 0;
    my @anchor_trace;
    my $s            = undef;
    my $e            = undef;
    my $i            = 0;
    my $anchor_skip  = 0;
    my $accel_max    = $self->{accel_max};
    my $speed_max    = $self->{speed_max};
    my $distance_max = $self->{distance_max};
    my $anchor_min   = $self->{anchor_min};

    $ds_primitive->iterator_reset;
    my $coord_first = $ds_primitive->iterator_next;
    my @distances;
    while ( my $coord = $ds_primitive->iterator_next ) {
        $i++;
        my $m = $coord->[REC_METADATA];
        push @distances, $m->{distance_since_previous};

        if ( 
            ( $m->{velocity} <= $speed_max ) and
            ( $m->{accel}    <= $accel_max )
        ) {
            $s ||= $i;
            if ( $i - $s >= $anchor_min ) {
                $e = $i;
            };
        }
        else {
            $e and push @anchor_trace, [ $s, $e, $e - $s ];
            $s = undef;
            $e = undef;
        };
    }
    $e and push @anchor_trace, [ $s, $e, $e - $s ];
    my $entries = $i;

# We want to remove the top 1% of distance jumps
    unless ( $distance_max ) {
        my @distances_sorted = sort {$a<=>$b} @distances;
        my $entries = 0+@distances_sorted;
        my $base_proportion = int($entries*0.01);
        $distance_max = $distances_sorted[-$base_proportion];
    }

# Now find the longest anchor trace from which we will work
# going outwards
    my $anchor = [0,0,0];
    my $anchor_i = 0;
    for my $j ( 0..$#anchor_trace ) {
        my $a = $anchor_trace[$j];
        next if $a->[2] <= $anchor->[2];
        $anchor   = $a;
        $anchor_i = $j;
    }

# Now we have the anchor, start measuring to the end
    my @drop_ids;
    my $last_good_velocity = 0;
    my $last_good_j        = 0;
    my $state              = 0;
    my $j                  = $anchor->[1];
    my $last_good_coord    = $ds_primitive->get($j-1);
    my $distance_since_previous = 0;

# Iterate through each to the end starting from the largest anchor
    while ( $j <= $entries ) {
        my $this_coord     = $ds_primitive->get($j-1);
        my $distance       = $last_good_coord ? distance($last_good_coord, $this_coord) : 0;
        my $tdelta         = $last_good_coord ? $this_coord->[REC_TIMESTAMP] - $last_good_coord->[REC_TIMESTAMP] : 0;
        my $velocity       = $tdelta ? $distance / $tdelta : 0;
        my $accel          = $tdelta ? ( $velocity - $last_good_velocity ) / $tdelta : 0;
        $distance_since_previous = $this_coord->[REC_METADATA]{distance_since_previous} || $distance_since_previous;

# If this coordinate passes through our exceptions filter
        if ( ( $velocity <= $speed_max ) 
            and ( $accel    <= $accel_max ) 
            and $distance_since_previous < $distance_max
        ) {
            $last_good_j        = $j;
            $last_good_velocity = $velocity;
            $last_good_coord    = $this_coord;
        }
# And if this coordinate does fails the exceptions check
        else {
            unshift @drop_ids, $j;
            $state = 1;
        }
        $j++;
    }

# Now work backwards from the largest anchor position
    $last_good_velocity = 0;
    $last_good_j        = 0;
    $state              = 0;
    $j                  = $anchor->[0];
    $last_good_coord    = $ds_primitive->get($j-1);

# Start going through to the first entry
    $j = $anchor->[0];
    while ( $j >= 0 ) {
        my $this_coord     = $ds_primitive->get($j-1);
        my $distance       = $last_good_coord ? distance($last_good_coord, $this_coord) : 0;
        my $tdelta         = $last_good_coord ? $this_coord->[REC_TIMESTAMP] - $last_good_coord->[REC_TIMESTAMP] : 0;
        my $velocity       = $tdelta ? $distance / $tdelta : 0;
        my $accel          = $tdelta ? ( $velocity - $last_good_velocity ) / $tdelta : 0;
        $distance_since_previous = $this_coord->[REC_METADATA]{distance_since_previous} || $distance_since_previous;

# If this coordinate passes through our exceptions filter
        if (    ( $velocity <= $speed_max ) 
            and ( $accel    <= $accel_max ) 
            and $distance_since_previous < $distance_max
        ) {
            $last_good_j        = $j;
            $last_good_velocity = $velocity;
            $last_good_coord    = $this_coord;
        }
# And if this coordinate does fails the exceptions check
        else {
            unshift @drop_ids, $j;
            $state = 1;
        }

        $j--;
    };

# Now remove the troublesome entries
    for my $id ( sort {$b<=>$a} @drop_ids ) {
        $ds_primitive->splice( $id, 1 );
    }

# Cleanup velocity/accel/etc data 
    $ds_primitive->filter(FILTER_ENRICH);

    return $self;
}

1;
