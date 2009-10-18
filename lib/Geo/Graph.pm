package Geo::Graph;

use strict;

use vars qw/$GEO_ATTRIBS $VERSION @EXPORT_OK %EXPORT_TAGS $CONSTANTS_LOOKUP @CONSTANTS @ISA/;

use constant ( $CONSTANTS_LOOKUP = {
        DATASET_TRACK        => 'Geo::Graph::Dataset::Primitive::Track',
        DATASET_SHAPE        => 'Geo::Graph::Dataset::Primitive::Shape',
        DATASET_WAYPOINTS    => 'Geo::Graph::Dataset::Primitive::Waypoints',

        FILTER_CLEAN         => 'Geo::Graph::Dataset::Filter::Clean',
        FILTER_SIMPLIFY      => 'Geo::Graph::Dataset::Filter::Simplify',
        FILTER_ENRICH        => 'Geo::Graph::Dataset::Filter::Enrich',

        OVERLAY_TRACK        => 'Geo::Graph::Overlay::Primitive::Track',
        OVERLAY_POINT        => 'Geo::Graph::Overlay::Primitive::Point',
        OVERLAY_IMAGE        => 'Geo::Graph::Overlay::Primitive::Image',
        OVERLAY_REGION       => 'Geo::Graph::Overlay::Primitive::Region',

        SHAPE_TRACK          => 'Geo::Graph::Overlay::Track',
        SHAPE_POINT          => 'Geo::Graph::Overlay::Point',
        SHAPE_IMAGE          => 'Geo::Graph::Overlay::Image',
        SHAPE_REGION         => 'Geo::Graph::Overlay::Region',

        IMAGE_DIRTY          => 1,
        IMAGE_CLEAN          => 0,

        VIEWPORT_GEOMETRY_DEFAULT => [640,480],

        COORD_X              => 0,
        COORD_Y              => 1,
        COORD_Z              => 2,
        COORD_LON            => 0,
        COORD_LAT            => 1,
        COORD_ALT            => 2,

        EARTH_RADIUS         => 6372797.6,

        GEOMETRY_WIDTH       => 0,
        GEOMETRY_HEIGHT      => 1,
        GEOMETRY_DEPTH       => 2,
        GEOMETRY_OFFSET_X    => 3,
        GEOMETRY_OFFSET_Y    => 4,
        GEOMETRY_OFFSET_Z    => 5,
        GEOMETRY_OFFSET_LON  => 3,
        GEOMETRY_OFFSET_LAT  => 4,
        GEOMETRY_OFFSET_ALT  => 5,
        GEOMETRY_OPTIONS     => 6,

        RANGE_MIN_LAT        => 0,
        RANGE_MIN_LON        => 1,
        RANGE_MIN_ALT        => 2,
        RANGE_MAX_LAT        => 3,
        RANGE_MAX_LON        => 4,
        RANGE_MAX_ALT        => 5,

        REC_LONGITUDE        => 0,
        REC_LATITUDE         => 1,
        REC_ALTITUDE         => 2,
        REC_TIMESTAMP        => 3,
        REC_METADATA         => 4,

        THIN_BY_DISTANCE     => 'thin_by_distance',
        THIN_BY_TIME         => 'thin_by_time',
        THIN_TO_COUNT        => 'thin_to_count',


        ZOOM_MIN             => 0,
        ZOOM_MAX             => 1,
    } );

use Geo::Graph::Base;
use Exporter;

@ISA = qw( Exporter Geo::Graph::Base );
@CONSTANTS = keys %$CONSTANTS_LOOKUP;

@EXPORT_OK = ( @CONSTANTS );
%EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    constants => \@CONSTANTS,
);

$VERSION = '0.0.1';
$GEO_ATTRIBS = {
    tile_class        => 'Geo::Graph::Tiles::OSM',
    tile_obj          => undef,
    data_class        => 'Geo::Graph::Dataset',
    canvas_class      => 'Geo::Graph::Canvas',
    canvas_obj        => undef,
    viewport_dirty    => 1,      # marks that the image needs to be generated

    cache_path        => undef,  # Where to store tile files, etc

    map_range         => undef,  # [0,0,0,0,0,0] - The maximum lat/lon/alt range to be shown. undef causes extent calculation
    map_zoom          => undef,  # zoom level. Where 1 is whole world at 255x255
    viewport_geometry_hint => undef,  # the pixel size of the map

    overlays          => [],
    viewport_geometry => VIEWPORT_GEOMETRY_DEFAULT, # the size of the image that will be generated
    iterator_index    => 0,
};

sub new {
# --------------------------------------------------
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);

# So we can override the cache location via environment variable
    if ( $ENV{GEO_GRAPH_CACHE_PATH} ) {
        $self->{cache_path} = $ENV{GEO_GRAPH_CACHE_PATH};
    };

    return $self;
}

sub load {
# --------------------------------------------------
# Attempt to load a single gps related file/buffer into 
# the local memory and set it up as the primary datasource
#
    my ( $self, $data, $opts ) = @_;
    require Geo::Graph::Overlay;
    my $ovl = Geo::Graph::Overlay->load($data);

# Rack it
    push @{$self->{overlays}}, $ovl;

    return $self;
}

sub overlay {
# --------------------------------------------------
    my ( $self, $type, $data, $opts ) = @_;

# Load the handling module
    $type =~ /^\w+(::\w+)*$/ or return;
    eval "require $type";
    $@ and die "Could not load $type because $@"; # FIXME

# Load up the data
    $opts ||= {};
    my $data_class = $self->{data_class} or return;
    $data_class =~ /^\w+(::\w+)*$/ or return;
    eval "require $data_class";
    $@ and die "Could not load $data_class because $@"; # FIXME
    $data = $data_class->load($data);

# Create the overlay
    my $overlay_opts = {%$opts};
    $overlay_opts->{data} = $data;
    my $overlay = $type->new($overlay_opts) or die "Could not create $type";

# Rack it
    push @{$self->{overlays}}, $overlay;

# Mark the graph as dirty and in need of a regeneration
    $self->{viewport_dirty} = IMAGE_DIRTY;

# We're done.
    return 0+@{$self->{overlays}};
}

sub overlays {
# --------------------------------------------------
# Returns the number of overlays that this system
# is handling
#
    my $self = shift;
    return 0+@{$self->{overlays}};
}

sub overlay_get {
# --------------------------------------------------
# Fetch a single overlay by index 
#
    my ( $self, $i ) = @_;
    return unless $self->overlays;
    return unless $i < $self->overlays;
    return $self->{overlays}[$i];
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
    return unless ref $self->{overlays} eq 'ARRAY';
    return if $self->overlays <= $self->{iterator_index};
    return $self->{overlays}[$self->{iterator_index}++];
}

sub iterator_eof {
# --------------------------------------------------
# Returns a true value if the iterator index has reached
# the limit of the records in this dataset
#
    my ( $self ) = @_;
    return unless ref $self->{overlays} eq 'ARRAY';
    return $self->overlays <= $self->{iterator_index};
}

sub range {
# --------------------------------------------------
# Calculate the maximum boundaries that this graph will
# need to occupy
#
    my ( $self ) = @_;
    my $overlays = $self->{overlays} or return;

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

sub range_center {
# --------------------------------------------------
# Given a range data structure, returns the point
# at the center of the range
#
    my ( $self, $range ) = @_;
    my $coord = [
        ( $range->[RANGE_MAX_LON] + $range->[RANGE_MIN_LON] ) / 2,
        ( $range->[RANGE_MAX_LAT] + $range->[RANGE_MIN_LAT] ) / 2,
        ( $range->[RANGE_MAX_ALT] + $range->[RANGE_MIN_ALT] ) / 2,
    ];
    return $coord;
}

sub tile_obj {
# --------------------------------------------------
# Instantiate the tile object as required. note this
# is a create once and cache function.
#
    my ( $self ) = @_;
    my $tile_obj = $self->{tile_obj} ||= do {
        eval "require $self->{tile_class}";
        $@ and die "Could not load $self->{tile_class} because '$@'";
        $self->{tile_class}->new($self);
    };
    return $tile_obj;
}

sub generate {
# --------------------------------------------------
# This code will generate the canvas and draw the image
#
    my ( $self, $opts ) = @_;

# Figure out what the automatic range are unless we have
# range already assigned
    my $map_range = $self->{map_range} || $self->range;

# Figure out what the image geometry is
    my $viewport_geometry = $self->{viewport_geometry} || VIEWPORT_GEOMETRY_DEFAULT;

# Calculate the optimal map geometry if required. Note that
# we can only hint. The viewport remains constant, however, the
# scale at which the image will be rendered may vary somewhat.
    my $tile_obj = $self->tile_obj;
    my $map_geometry = $tile_obj->map_geometry(
                            $map_range,
                            $viewport_geometry,
                            $self->{viewport_geometry_hint},
                            $opts
                        );

# Now calculate the optimal viewport geometry offset if required
    $viewport_geometry = $tile_obj->viewport_geometry(
                            $map_range,
                            $viewport_geometry,
                            $self->{viewport_geometry_hint},
                            $map_geometry,
                            $opts
                        );

# Create the image object
    require Geo::Graph::Canvas;
    my $canvas_obj = Geo::Graph::Canvas->new(
                            map_range         => $map_range,
                            map_geometry      => $map_geometry,
                            viewport_geometry => $viewport_geometry
                        );

# Then we merge all the layers together.
# 1. Lay down the base tiles
    $tile_obj->canvas_tiles_draw( $canvas_obj );

# 2. Go through each of the overlays and get them to draw
#    their data onto the canvas surface
    for my $overlay ( @{$self->{overlays}||[]} ) {
        $overlay->canvas_draw($canvas_obj);
    }

    $self->{viewport_dirty} = IMAGE_CLEAN;

    return $canvas_obj;
}

sub png {
# --------------------------------------------------
    my ( $self, $opts ) = @_;
    my $canvas_obj = $self->generate or return;
    return $canvas_obj->png;
}

1;
