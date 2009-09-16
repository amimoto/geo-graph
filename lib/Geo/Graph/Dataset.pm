package Geo::Graph::Dataset;

use strict;
use vars qw/ $HAS_GPSBABEL $HANDLER_MAP $HANDLER_DEFAULT /;

$HANDLER_MAP = {
    gpx => 'Geo::Graph::Dataset::GPX',
};
$HANDLER_DEFAULT = 'Geo::Graph::Dataset::GPSBabel';
use Geo::Graph qw/ :constants /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        data            => undef,
        handler_map     => undef,
        handler_default => $HANDLER_DEFAULT,
        section_index   => 0,
        iterator_index  => 0,
    };

sub init {
# --------------------------------------------------
    my $self = shift;
    my $opts = $self->parameters( @_ );
    my $handler_map = {%$HANDLER_MAP};
    my $handler_map_new = $opts->{handler_map} ||= {};
    @$handler_map{keys %$handler_map_new} = values %$handler_map_new;
    $opts->{handler_map} = $handler_map;
    
    return $self->init_instance_attribs($opts);
}

sub load {
# --------------------------------------------------
# Attempt to do magic autoloading of the data provided.
# Since this is the base class, we do some sneaky stuff 
# by trying to autodetect what type of data we are working
# with and then dispatching it to the correct driver class.
# Note that this is just the trigger to convert the data 
# into a useable format for Geo::Graph. 
#
    my ( $self, $data ) = @_;

    ref $self or $self = $self->new;
    $data ||= $self->{data} or return;

    my $data_processor = '';
    LOAD_ATTEMPT : {

# Already converted?
        if ( ref $data ) {
            $data_processor = ref $self; # basically means "ignore me"
            last;
        }

# This is a path
        if ( 
            -f $data and 
            my $format = $self->fpath_format_detect( $data ) 
        ) {
            $data_processor = $self->{handler_map}{$format} || $self->{handler_default} || '';
            last;
        }

# Data has already been loaded, let's do the
# conversion as a string. Pass as ref to avoid making
# a copy of the text which may be big
        my $format = $self->string_format_detect( \$data ) or last;
        $data_processor = $self->{handler_map}{$format} || $self->{handler_default} || '';

    };

# Now we need to massage the code
    if ( $data_processor ne ref $self ) {
        $data_processor =~ /^\w+(::\w+)*$/ or return;
        eval "require $data_processor";
        $@ and die "Could not load $data_processor because $@"; # FIXME
        $data = $data_processor->load( $data );
    }

    return ( $self->{data} = $data );
}

sub string_format_detect {
# --------------------------------------------------
# Attempt to identify the GPS data via the headers
# in the string
#
    my ( $self, $data_ref ) = @_;
    my $header_buf = substr $$data_ref, 0, 1024;
    if ( $header_buf =~ m|http://www.topografix.com/GPX/1/0| ) {
        return 'gpx';
    }
    return;
}

sub fpath_format_detect {
# --------------------------------------------------
# Attempt to identify the GPS data via the pathname
# using extensions
#
    my ( $self, $fpath ) = @_;
    $fpath =~ /(\w+)$/ or return;
    my $ext = lc $1;
    if ( $ext eq 'gpx' ) {
        return $ext;
    };
    return;
}

sub sections {
# --------------------------------------------------
# Some data types may have multiple sections (eg multiple
# tracks in a GPX file. Account for this here) This function
# will return the number of different sections this dataset
# holds.
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return 1;
}

sub section_select {
# --------------------------------------------------
# Some data types may have multiple sections (eg multiple
# tracks in a GPX file. Account for this here) This 
# function will allow the user to choose between multiple 
# sections for iteration and analysis
#
    my ( $self, $section_index ) = @_;
    return 0 unless my $section_count = $self->sections;
    return if $section_count < $section_index;
    return $self->{section_index} = $section_index;
}

sub entries {
# --------------------------------------------------
# Number of GPS points in the dataset
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return 0+@{$self->{data}};
}

sub iterator_reset {
# --------------------------------------------------
# Moves the iterator index to the first entry in the
# list
#
    my ( $self ) = @_;
    $self->{iterator_index} = 0;
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
#          { additional metadata }
#      ]
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return if $self->entries <= $self->{iterator_index};
    my $rec = $self->{data}[$self->{iterator_index}++];
    return $rec;
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
# better performance
#
    my ( $self ) = @_;

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

    return \@range;
}

1;
