package Geo::Graph::Dataset::Primitive;

# A simple dataset represents a single strip of data.
# ie. A single track, a single shape, or a group of waypoints
#     This is not the same thing as a composite dataset which 
#     can contain multiple data and data types. 

use strict;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        data           => [],
        overlay_hint   => undef,
        iterator_index => 0,
        _range         => undef,
    };

sub new {
# --------------------------------------------------
# We support some syntax sugar here. If the instantiation 
# parameter provided is an arrayref, we assume that they
# just want to set the data
#
    my $pkg = shift;
    if ( @_ and ref $_[0] eq 'ARRAY' ) {
        my $data = shift @_;
        my $self = $pkg->SUPER::new(@_);
        $self->{data} = $data;
        return $self;
    }
    return $pkg->SUPER::new(@_);
}

sub insert {
# --------------------------------------------------
# Insert a single data element into the data
#

# We're simplifying
#    my ($self,@data) = @_;
    return push @{shift()->{data}}, @_;
}

sub splice {
# --------------------------------------------------
# Does the same thing as perl's splice on the
# point data 
#

# We're simplifying
#    my ( $self, @splice_data ) = @_;
    return splice @{shift()->{data}}, @_;
}

sub filter {
# --------------------------------------------------
# Apply a number of filters to the data found in the
# current section
#
    my ( $self, $filter_name, $opts ) = @_;

# Handle how constants are not functional when DATASET_XXX => value
# is used in hash context
    $filter_name  =~ /^FILTER_/ and $filter_name = $Geo::Graph::CONSTANTS_LOOKUP->{$filter_name};
    return unless $filter_name =~ /^\w+(::\w+)+$/;

    eval "require $filter_name; 1" or do { 
        die "Could not load $filter_name because $@"; 
    };
    no strict 'refs';
    my $filter_obj = $filter_name->new($opts) or return die "Could not load $filter_name";
    use strict 'refs';

    return $filter_obj->filter($self);
}

sub entries {
# --------------------------------------------------
# Number of GPS points in the dataset
#
    return 0+@{$_[0]->{data}||[]};
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
# Each record returned should be simply an array
# reference in the format:
#
#      [
#          $longitude,
#          $latitude,
#          $altitude,
#          $timestamp,
#          { additional metadata }
#      ]
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return if $#{$self->{data}} < $self->{iterator_index};
    return $self->{data}[$self->{iterator_index}++];
}

sub iterator_eof {
# --------------------------------------------------
# Returns a true value if the iterator index has reached
# the limit of the records in this dataset
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return $self->entries <= $self->{iterator_index};
}

sub range {
# --------------------------------------------------
# Usually called by Geo::Graph::Overlay, this returns
# the boundaries within which this dataset describes.
# Note that this function may be subclassed to provide
# better performance. Note that this will clobber the 
# current iterator index
#
    my ( $self ) = @_;

    return $self->{_range} if $self->{_range};

    my @range = qw( 10000 10000 10000 -10000 -10000 -10000  );

# Iterate through all the points and find the range of this dataset
# Yes... it's slow for large datasets. What can I do?
    $self->iterator_reset;
    while ( my $point = $self->iterator_next ) {

# Handle latitude range
        if ( $range[RANGE_MIN_LAT] > $point->[REC_LATITUDE] ) {
            $range[RANGE_MIN_LAT] = $point->[REC_LATITUDE];
        }
        if ( $range[RANGE_MAX_LAT] < $point->[REC_LATITUDE] ) {
            $range[RANGE_MAX_LAT] = $point->[REC_LATITUDE];
        }

# Handle longitude range
        if ( $range[RANGE_MIN_LON] > $point->[REC_LONGITUDE] ) {
            $range[RANGE_MIN_LON] = $point->[REC_LONGITUDE];
        }
        if ( $range[RANGE_MAX_LON] < $point->[REC_LONGITUDE] ) {
            $range[RANGE_MAX_LON] = $point->[REC_LONGITUDE];
        }

# Handle altitudinal range
        if ( $range[RANGE_MIN_ALT] > $point->[REC_ALTITUDE] ) {
            $range[RANGE_MIN_ALT] = $point->[REC_ALTITUDE];
        }
        if ( $range[RANGE_MAX_ALT] < $point->[REC_ALTITUDE] ) {
            $range[RANGE_MAX_ALT] = $point->[REC_ALTITUDE];
        }

    }

    return $self->{_range} ||= \@range;
}

1;
