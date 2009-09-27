package Geo::Graph::Dataset;

use strict;

# This handles the individual load/release of the various primitive 
# datatypes

use Data::Dumper;
use vars qw/ $AUTOLOAD /;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        datasets       => [],
        dataset_selected => undef,
    };

# Handle any combination of tracks/waypoints/shapes

sub new {
# --------------------------------------------------
# There is some very specific "tricky" syntax that we'll
# use here to support some syntax sugar. That is, users
# can define a sequence of primitives and datasets right 
# away. 
#
# Eg:
#
#   my $ds = Geo::Graph::Dataset->new(
#       DATASET_TRACK => [ ...data... ], # passed directly into the primitive's create
#       DATASET_SHAPE => [ ...data... ],
#       DATASET_SHAPE => [ ...data... ],
#       OPTION1 => VALUE1, # Note that this can also be a hash if preferred (but not both)
#   )
#
# Note that the last dataset object specified will be the 
# active dataset in the sequence.
#
    my $pkg = shift;

# Iterate through the parameters and find out if there any primitives 
# being initialized.
    my @primitives;
    while ( @_ ) {

        last if ref $_[0];

        my $k = $_[0];
# Handle how constants are not functional when DATASET_XXX => value
# is used in hash context
        $k =~ /^DATASET_/ and $k = $Geo::Graph::CONSTANTS_LOOKUP->{$k};

# must be pointing to some package
        last unless $k and $k =~ /::/; 

# Get the primitives init parameters 
        my ( $primitive, $init_params ) = splice @_, 0, 2;
        push @primitives, [$k, $init_params];
    }

# Initialize our object
    my $self = $pkg->SUPER::new(@_);

# If any primitives need instantiation, we'll do so here
    HANDLE_PRIMITIVES: {
        @primitives or last HANDLE_PRIMITIVES;
        for my $primitive_options ( @primitives ) {
            my ( $primitive, $init_params ) = @$primitive_options;
            eval "require $primitive; 1" or  do{
                die "Could not load '$primitive' because $@";
            };
            no strict 'refs';
            my $data_primitive = $primitive->new($init_params);
            use strict 'refs';
            $self->dataset_insert( $data_primitive );
        }

# Select the last primitive defined
        $self->dataset_select( @primitives-1 ); # zero-index so...
    };

    return $self;
}

sub datasets {
# --------------------------------------------------
# Return the number of primitives in the dataset we 
# have here
#
    my $self = shift;
    return 0+@{$self->{datasets}};
}

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
    my @removed = splice @{$self->{datasets}}, @_;

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
    return ( $self->{dataset_selected} = $self->{datasets}[$i] );
}

sub range {
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

sub AUTOLOAD {
# --------------------------------------------------
# We will chain requests down to the dataset primitive
# if required
#
    my $self = shift;

# If there is no active dataset, we can ignore it
    if ( my $ds = $self->{dataset_selected} ) {
# and if there is, let's see if we can call the function on the dataset
        my ($attrib) = $AUTOLOAD =~ /::([^:]+)$/;
        if ( $ds->can($attrib) ) {
            return $ds->$attrib(@_);
        }
    }

# No we can't, so we won't bother. Hand over the call to the parent
    $Geo::Graph::Base::AUTOLOAD = $AUTOLOAD;
    return $self->SUPER::AUTOLOAD(@_);

}

1;
