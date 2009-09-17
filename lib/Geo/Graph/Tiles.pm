package Geo::Graph::Tiles;

use strict;
use vars qw/ $HAS_GPSBABEL $HANDLER_MAP $HANDLER_DEFAULT /;

use Geo::Graph qw/ :constants /;
use Geo::Graph::Utils;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        map_geometry  => undef,
        tile_geometry => [ 255, 255 ],
        tile_range    => [ -85.0511287798,-180, 0, 85.0511287798, 179.9999999, 0 ],
        zoom_range    => [ 10, 15 ],
        cache_path    => '',
    };

sub map_geometry {
# --------------------------------------------------
# Calculate the optimal viewport for the all the 
# image parameters provided
#
    my ( $self, 
         $map_range, 
         $viewport_geometry, 
         $viewport_geometry_hint, 
         $opts ) = @_;

    $opts ||= {};
    $viewport_geometry_hint ||= [];

# Sanity tests
    return unless $viewport_geometry;
    return unless $map_range;

# Some defaults
    my $zoom         = $opts->{zoom};

# If the zoom has not yet been set, we will attempt to derive the best 
# zoom factor for the job. It's kind of a silly way of doing it, but
# we'll zoom into the frame until we can't hold the map anymore... 
# then take one step back and treat that as the zoom factor.
    $zoom ||= $self->zoom_optimize(
         $map_range, 
         $viewport_geometry, 
         $viewport_geometry_hint, 
         $opts 
    );

# With the zoom factor, we can calculate how many pixels wide the entire
# map will be
    my $pixel_count = 256 * ( 2**$zoom );

    my $map_geometry = [
        $pixel_count, # width
        $pixel_count, # height
        0,            # altitude
        0,            # x offset
        0,            # y offset
        0,            # z offset
        {
            zoom => $zoom,
        },
    ];

    return $map_geometry;
}

sub viewport_geometry {
# --------------------------------------------------
# Assuming we know what the full extents of the map are, we can
# now calculate the offset for the viewport. Perhaps at some
# point in the future , it'll be possible to calculate optimal 
# viewport size based upon the dataset but not yet.
#
    my ( $self, 
         $map_range, 
         $viewport_geometry, 
         $viewport_geometry_hint, 
         $map_geometry,
         $opts ) = @_;

    $opts ||= {};
    $viewport_geometry_hint ||= [];

    VIEWPORT_OFFSET_CALC: {

# If the viewport geometry has already got a definition setup,
# we'll go with that instead
        if ( defined $viewport_geometry_hint->[GEOMETRY_OFFSET_X] ) {
            $viewport_geometry->[GEOMETRY_OFFSET_X] = $viewport_geometry_hint->[GEOMETRY_OFFSET_X] || 0;
            $viewport_geometry->[GEOMETRY_OFFSET_Y] = $viewport_geometry_hint->[GEOMETRY_OFFSET_Y] || 0;
            $viewport_geometry->[GEOMETRY_OFFSET_Z] = $viewport_geometry_hint->[GEOMETRY_OFFSET_Z] || 0;
            last;
        };

# If we got here, we'll see if there already is a provided viewport
# geometry offset. If that's been set, we'll use that.
        if ( defined $viewport_geometry->[GEOMETRY_OFFSET_X] ) {
            last;
        }

# Okay, we we have to do the calculation for the offset. Let's go
# about doing that now...
        my $coord_center = Geo::Graph->range_center( $map_range );
        my $coord_pixels = wgs84_to_cartesian( $coord_center, $map_geometry );

# Now we work backwards to find out what the viewport geometry should be. We put 
# the viewport's center to be in the center of the range that we're looking at
        $viewport_geometry->[GEOMETRY_OFFSET_X] = int( 
                                                        $coord_pixels->[COORD_X] 
                                                        - $viewport_geometry->[GEOMETRY_WIDTH] / 2 
                                                    );
        $viewport_geometry->[GEOMETRY_OFFSET_Y] = int( 
                                                        $coord_pixels->[COORD_Y] 
                                                        - $viewport_geometry->[GEOMETRY_HEIGHT] / 2 
                                                    );
        $viewport_geometry->[GEOMETRY_OFFSET_Z] = 0; # TODO not worried about Z yet
    };

    return $viewport_geometry;
}

sub zoom_optimize {
# --------------------------------------------------
# Attempt to derive the best zoom factor for the job. It's kind of a 
# silly way of doing it, but how we'll do the zooming is to zoom into 
# the frame until we can't hold the map anymore... then take one step 
# back and treat that as the zoom factor.
#
    my ( $self, $map_range, $viewport_geometry, $viewport_geometry_hint, $opts ) = @_;
    my $zoom = $self->{zoom_range}[ZOOM_MIN];

# We calculate the number of pixels for the zoom level
    my $tile_range = $self->{tile_range};

    while ( $zoom <= $self->{zoom_range}[ZOOM_MAX] ) {

# Figure out how the lat/lon rand maps to the pixels
        my $zoom_pixels = 256*2**$zoom; my $map_size = [ $zoom_pixels, $zoom_pixels ];
        my $coord_ul = wgs84_to_cartesian( [$map_range->[RANGE_MAX_LON],$map_range->[RANGE_MAX_LAT]], $map_size );
        my $coord_lr = wgs84_to_cartesian( [$map_range->[RANGE_MIN_LON],$map_range->[RANGE_MIN_LAT]], $map_size );

#### Handle the longitudinal zoom
        my $lon_pixels = $coord_ul->[COORD_X] - $coord_lr->[COORD_X];
        last if $lon_pixels > $viewport_geometry->[GEOMETRY_WIDTH];

#### Handle the latitudinal zoom
        my $lat_pixels = $coord_ul->[COORD_Y] - $coord_lr->[COORD_Y];
        last if $lat_pixels > $viewport_geometry->[GEOMETRY_HEIGHT];

        $zoom++;
    };

    $zoom--;

    return $zoom;
}

sub lat_pixel_resolution {
# --------------------------------------------------
# Returns latitudinal degrees a pixel spans
#
    my ( $self, $zoom ) = @_;
    my $tile_range = $self->{tile_range};
    return ( ( $tile_range->[RANGE_MAX_LAT] -  $tile_range->[RANGE_MIN_LAT] )/( 256 * 2**($zoom-1) ) );
}


sub lon_pixel_resolution {
# --------------------------------------------------
# Returns longitudinal degrees a pixel spans
#
    my ( $self, $zoom ) = @_;
    my $tile_range = $self->{tile_range};
    return ( ( $tile_range->[RANGE_MAX_LON] -  $tile_range->[RANGE_MIN_LON] )/( 256 * 2**($zoom-1) ) );
}

sub canvas_tiles_draw {
# --------------------------------------------------
# This will draw the tile images onto the canvas.
# This function expects the map_geometry and viewport_geometry
# to be already loaded into the canvas
#
    my ( $self, $canvas_obj ) = @_;
    return 1; # we do nothing. Blank tiles :)
}

sub tile_coord {
# --------------------------------------------------
# Returns the coordinates of the tile's upper left
# pixel
#
    my ( $self, $tile_x, $tile_y ) = @_;
}

1;
