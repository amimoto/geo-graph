package Geo::Graph::Dataset::Filter::Clean;

use strict;
use Geo::Graph qw/ :constants/;
use Geo::Graph::Utils;
use Geo::Graph::Dataset::Filter
    ISA => 'Geo::Graph::Dataset::Filter',
    GEO_ATTRIBS => {
        accel_max   => 30,      # 30      m/s^2
        speed_max   => 300_000, # 300,000 m/s (speed of sound)
        anchor_min  => 5,       # minimum 5 points in the anchor
        entries_min => 10,      # don't bother unless 
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
    my $s           = undef;
    my $e           = undef;
    my $i           = 0;
    my $anchor_skip = 0;
    my $accel_max   = $self->{accel_max};
    my $speed_max   = $self->{speed_max};
    my $anchor_min  = $self->{anchor_min};

    $ds_primitive->iterator_reset;
    my $coord_first = $ds_primitive->iterator_next;
    while ( my $coord = $ds_primitive->iterator_next ) {
        $i++;
        my $m = $coord->[REC_METADATA];

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
    if ( $e ) { push @anchor_trace, [ $s, $e, $e - $s ] };

# Now find the longest anchor trace from which we will work
# going outwards
    my $anchor = [0,0,0];
    for my $a ( @anchor_trace ) {
        next if $a->[2] <= $anchor->[2];
        $anchor = $a;
    }

    use Data::Dumper; die Dumper $anchor;
}

1;
