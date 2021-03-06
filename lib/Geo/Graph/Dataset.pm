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
        dataset_primitives => [],
        dataset_selected   => undef,
        iterator_index     => 0,
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
        last unless $k and $k =~ /^\w+(::\w+)+$/; 

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
    return 0+@{$self->{dataset_primitives}};
}

sub dataset_create {
# --------------------------------------------------
# Inserts a new dataset based upon the method,options
# syntax. 
#
# eg:
# 
# my $ds = $obj->dataset_create( DATASET_SHAPE => [ ...data... ] );
#
    my ( $self, $primitive ) = splice @_, 0, 2;

# Handle how constants are not functional when DATASET_XXX => value
# is used in hash context
    $primitive =~ /^DATASET_/ and $primitive = $Geo::Graph::CONSTANTS_LOOKUP->{$primitive};

# Load the dataset primitive library
    eval "require $primitive; 1" or  do{
        die "Could not load '$primitive' because $@";
    };

# Create the object
    no strict 'refs';
    my $data_primitive = $primitive->new(@_) or return;
    use strict 'refs';

# Add the dataset to the local object and select the new dataset
# as the active
    my $data_primitive_obj = $self->dataset_insert( $data_primitive );
    $self->dataset_select( $self->datasets-1 ); # zero-index so...

# Done.
    return $data_primitive_obj;
}

sub dataset_insert {
# --------------------------------------------------
# Insert a new dataset
#
    my $self = shift;
    return push @{$self->{dataset_primitives}}, @_;
}

sub dataset_splice {
# --------------------------------------------------
# Does the same thing as perl's splice on the
# dataset
#
    my $self = shift;
    my @removed = splice @{$self->{dataset_primitives}}, @_;

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
    return ( $self->{dataset_selected} = $self->{dataset_primitives}[$i] );
}


sub iterator_reset {
# --------------------------------------------------
# Moves the iterator index to the first entry in the
# list
#
    $_[0]->{iterator_index} = 0;
    return 1;
}

sub iterator_next {
# --------------------------------------------------
# Yields the record the iterator index is currently
# pointing to. Also increments the iterator index.
# Each record returned should be simply a dataset
# primitive
    my ( $self ) = @_;
    return unless ref $self->{dataset_primitives} eq 'ARRAY';
    return if $self->datasets <= $self->{iterator_index};
    return $self->{dataset_primitives}[$self->{iterator_index}++];
}

sub iterator_eof {
# --------------------------------------------------
# Returns a true value if the iterator index has reached
# the limit of the records in this dataset
#
    my ( $self ) = @_;
    return unless ref $self->{dataset_primitives} eq 'ARRAY';
    return $self->datasets <= $self->{iterator_index};
}

sub range {
# --------------------------------------------------
    my ( $self ) = @_;
    return $self->{_range} if $self->{_range};

    my $datasets = $self->{dataset_primitives} or return;
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
