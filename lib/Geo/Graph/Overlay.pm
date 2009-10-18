package Geo::Graph::Overlay;

use strict;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        overlay_primitives => [],
        overlay_selected   => undef,
        iterator_index     => 0,
    };

sub new {
# --------------------------------------------------
# There is some very specific "tricky" syntax that we'll
# use here to support some syntax sugar. That is, users
# can define a sequence of overlay primitives using dataset
# primives or dataset object
#
# Eg:
#
#   my $overlay = Geo::Graph::Overlay->new(
#       $dataset,                            # This can be a Geo::Graph::Dataset object
#       OVERLAY_TRACK => $dataset_primitive, # Associate a dataset primitive with a particular overlay object
#       $dataset_primitive,                  # Use the dataset primitive's default overlay hint
#       OPTION1 => VALUE1,                   # Note that this can also be a hash if preferred (but not both)
#   )
#
# Note that the last dataset object specified will be the 
# active dataset in the sequence.
#
    my $pkg = shift;

    my @ovl_primitives;
    while ( @_ ) {
        my $k = $_[0];

# Rack the objects
        if ( 
            UNIVERSAL::isa( $k, 'Geo::Graph::Dataset' ) or
            UNIVERSAL::isa( $k, 'Geo::Graph::Dataset::Primitive' )
        ) {
            push @ovl_primitives, [shift()];
        }

        elsif ( $k and not ref $k ) {
# Handle how constants are not functional when DATASET_XXX => value
# is used in hash context
            $k =~ /^OVERLAY_/ and $k = $Geo::Graph::CONSTANTS_LOOKUP->{$k};

# must be pointing to some package
            last unless $k and $k =~ /^\w+(::\w+)*$/; 

            my ( $junk, $dataset_primitive ) = splice @_, 0, 2;
            push @ovl_primitives, [ $k, $dataset_primitive ];
        }

        else { last }
    }

# Initialize our object
    my $self = $pkg->SUPER::new(@_);

# If any primitives need instantiation, we'll do so here
    HANDLE_PRIMITIVES: {
        @ovl_primitives or last HANDLE_PRIMITIVES;
        for my $ovl_primitive_options ( @ovl_primitives ) {
            $self->overlay_primitive_create(@$ovl_primitive_options);
        };
    };

    return $self;
}

sub load {
# --------------------------------------------------
# A possibly useful macro to load a dataset into
# a new overlay object
#
    my ( $self, $data, $opts ) = @_;
    require Geo::Graph::Datasource;
    my $ds = UNIVERSAL::isa( $data, 'Geo::Graph::Datasource' ) 
                ? $data
                : Geo::Graph::Datasource->load($data,$opts);
       $ds or return;
    ref $self or $self = $self->new($ds,$opts);
    return $self;
}

sub overlay_primitive_create {
# --------------------------------------------------
#
    my ( $self ) = shift;

    return unless @_;

    my ( $primitive, $dataset_primitive );
# Handle syntax in the form
#       OVERLAY_TRACK => $dataset_primitive, # Associate a dataset_primitive primitive with a particular overlay object
    if ( not ref $_[0] ) {

        $primitive = shift;
        $dataset_primitive   = shift or return;

# Handle how constants are not functional when DATASET_XXX => value
# is used in hash context
        $primitive =~ /^OVERLAY_/ and $primitive = $Geo::Graph::CONSTANTS_LOOKUP->{$primitive};
    }

# Handle syntax in the form
#       $dataset_primitive,                  # Use the dataset_primitive primitive's default overlay hint
    elsif ( UNIVERSAL::isa($_[0],'Geo::Graph::Dataset::Primitive') ) {
        $dataset_primitive   = shift;
        $primitive = $dataset_primitive->{overlay_hint};
    }

# Handle syntax in the form
#       $dataset_primitive,                            # This can be a Geo::Graph::Dataset object
    elsif ( UNIVERSAL::isa($_[0],'Geo::Graph::Dataset') ) {
        my $dataset = shift;
        $dataset->iterator_reset;
        while ( my $dataset_primitive = $dataset->iterator_next ) {
            $self->overlay_primitive_create($dataset_primitive);
        }
        return;
    }

# Now load the overlay primitive
    eval "require $primitive; 1" or  do{
        die "Could not load '$primitive' because $@";
    };
    no strict 'refs';
    my $ovl_primitive = $primitive->new( dataset_primitive => $dataset_primitive, @_ );
    use strict 'refs';

# Add it to our stack...
    $self->overlay_primitive_insert($ovl_primitive);

    return $ovl_primitive;
}

sub overlay_primitive_insert {
# --------------------------------------------------
# Insert a new overlay
#
    my $self = shift;
    return push @{$self->{overlay_primitives}}, @_;
}

sub overlay_primitives {
# --------------------------------------------------
# Returns the number of overlay primitives on the system
#
    my $self = shift;
    return 0+@{$self->{overlay_primitives}};
}

sub overlay_primitive_get {
# --------------------------------------------------
# Fetch a single overlay by index 
#
    my ( $self, $i ) = @_;
    return unless $self->overlay_primitives;
    return unless $i < $self->overlay_primitives;
    return $self->{overlay_primitives}[$i];
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
    return unless ref $self->{overlay_primitives} eq 'ARRAY';
    return if $self->overlay_primitives <= $self->{iterator_index};
    return $self->{overlay_primitives}[$self->{iterator_index}++];
}

sub iterator_eof {
# --------------------------------------------------
# Returns a true value if the iterator index has reached
# the limit of the records in this dataset
#
    my ( $self ) = @_;
    return unless ref $self->{overlay_primitives} eq 'ARRAY';
    return $self->overlay_primitives <= $self->{iterator_index};
}

sub load_dataset {
# --------------------------------------------------
# This associates a dataset with an overlay object.
# The input can be a file path, raw text, or another
# dataset itself.
#
    my ( $self, $dataset, $opts ) = @_;

# Iterate through each dataset primitive associating
# the dataset primitive with a particular overly as
# required
    $dataset->iterator_reset;
    while ( my $ds_primitive = $dataset->iterator_next ) {
    }
}

sub load_dataset_primitive {
# --------------------------------------------------
# Load a single dataset primitive into this overlay
# collection
#
    my ( $self, $ds_primitive, $overlay_object ) = @_;
}

sub data_load {
# --------------------------------------------------
# This associates a dataset with an overlay object.
# The input can be a file path, raw text, or another
# dataset itself.
#
}

sub range {
# --------------------------------------------------
# This should be overriden by the subclass to return
# the maxium boundaries (range) that this overlay
# layer will take. Six parameters are returned
#
# 1. min latitude
# 2. min longitude
# 3. min altitude
# 4. max latitude
# 5. max longitude
# 6. max altitude
#
    my $self = shift;
    my $overlays = $self->{overlay_primitives} or return;

    my @graph_range = qw( 10000 10000 10000 -10000 -10000 -10000  );

    for my $overlay (@$overlays) {
        my $overlay_range = $overlay->range;

# Handle latitude range
        if ( $graph_range[RANGE_MIN_LAT] > $overlay_range->[RANGE_MIN_LAT] ) {
            $graph_range[RANGE_MIN_LAT] = $overlay_range->[RANGE_MIN_LAT];
        }
        if ( $graph_range[RANGE_MAX_LAT] < $overlay_range->[RANGE_MAX_LAT] ) {
            $graph_range[RANGE_MAX_LAT] = $overlay_range->[RANGE_MAX_LAT];
        }

# Handle longitude range
        if ( $graph_range[RANGE_MIN_LON] > $overlay_range->[RANGE_MIN_LON] ) {
            $graph_range[RANGE_MIN_LON] = $overlay_range->[RANGE_MIN_LON];
        }
        if ( $graph_range[RANGE_MAX_LON] < $overlay_range->[RANGE_MAX_LON] ) {
            $graph_range[RANGE_MAX_LON] = $overlay_range->[RANGE_MAX_LON];
        }

# Handle altitudinal range
        if ( $graph_range[RANGE_MIN_ALT] > $overlay_range->[RANGE_MIN_ALT] ) {
            $graph_range[RANGE_MIN_ALT] = $overlay_range->[RANGE_MIN_ALT];
        }
        if ( $graph_range[RANGE_MAX_ALT] < $overlay_range->[RANGE_MAX_ALT] ) {
            $graph_range[RANGE_MAX_ALT] = $overlay_range->[RANGE_MAX_ALT];
        }
    }

    return \@graph_range;
}

sub canvas_draw {
# --------------------------------------------------
    my ( $self, $canvas_obj ) = @_;
    my $overlays = $self->{overlay_primitives} or return;
    my @graph_range = qw( 10000 10000 10000 -10000 -10000 -10000  );
    for my $overlay (@$overlays) {
        $overlay->canvas_draw($canvas_obj);
    };
    return 1;
}

1;
