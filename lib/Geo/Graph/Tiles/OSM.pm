package Geo::Graph::Tiles::OSM;

use strict;
use LWP::Simple;
use Math::Trig;
use Geo::Graph::Utils;
use Geo::OSM::Tiles qw/ :all /;
use Geo::Graph qw/:constants/;
use Geo::Graph::Tiles;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Tiles',
    GEO_ATTRIBS => {
    };

sub canvas_tiles_draw {
# --------------------------------------------------
# This will draw the tile images onto the canvas.
# This function expects the map_geometry and viewport_geometry
# to be already loaded into the canvas
#
    my ( $self, $canvas_obj ) = @_;

# Start iterating through the image, by row, from top left
# to lower right.
    my $map_geometry      = $canvas_obj->{map_geometry};
    my $viewport_geometry = $canvas_obj->{viewport_geometry};
    my $zoom              = $map_geometry->[GEOMETRY_OPTIONS]{zoom} || 0;

# We know what the viewport geometry is, so we work backwards from those pixel extents
    my $ul_coord   = cartesian_to_wgs84( 
                            [ $viewport_geometry->[GEOMETRY_OFFSET_X], $viewport_geometry->[GEOMETRY_OFFSET_Y] ],
                            $map_geometry 
                        );
    my $lr_coord   = cartesian_to_wgs84( 
                            [ 
                                $viewport_geometry->[GEOMETRY_OFFSET_X] + $viewport_geometry->[GEOMETRY_WIDTH], 
                                $viewport_geometry->[GEOMETRY_OFFSET_Y] + $viewport_geometry->[GEOMETRY_HEIGHT],
                            ],
                            $map_geometry 
                        );

# Find the start tile
    my $tile_ul_x  = lon2tilex($ul_coord->[COORD_LON],$zoom);
    my $tile_ul_y  = lat2tiley($ul_coord->[COORD_LAT],$zoom);

# Find the end tile
    my $tile_lr_x  = lon2tilex($lr_coord->[COORD_LON],$zoom);
    my $tile_lr_y  = lat2tiley($lr_coord->[COORD_LAT],$zoom);

    my $scale = 1; # no rescaling
    my $alpha = 0; # no alpha
    for my $tile_x ( $tile_ul_x .. $tile_lr_x ) {
        for my $tile_y ( $tile_lr_y .. $tile_ul_y ) {
            my $tile_data_ref = $self->tile_fetch($tile_x,$tile_y,$zoom);
            my $tile_coords   = $self->tile_coord($tile_x,$tile_y,$zoom);
            $canvas_obj->png_overlay(
                $tile_data_ref,
                $tile_coords,
                $alpha,
                $scale # defaults to 1 but we'll be explicit here
            );
        }
    }

    return 1;
}

sub tile_fetch {
# --------------------------------------------------
# Loads a single tile from OSM. Returns the raw PNG
# data.
#
    my ( $self, $tile_x, $tile_y, $zoom ) = @_;

# Check the cache if we have one
    CACHE_LOAD: {
        my $cache_path = $self->{cache_path} or last CACHE_LOAD;

        my $cache_fpath = "$cache_path/osm-$zoom-$tile_x-$tile_y.png";

        -f $cache_fpath or last CACHE_LOAD;

        open my $fh, "<$cache_fpath" or last CACHE_LOAD;

        local $/;
        my $data = <$fh>;
        $data or last CACHE_LOAD;

        return \$data;
    };

# We have to download 'er
    my $url_path = "http://tile.openstreetmap.org/" . tile2path($tile_x,$tile_y,$zoom);
    my $data = get( $url_path );

# Store the tile data in the cache if the cache path has been set
    $self->tile_store($tile_x,$tile_y,$zoom,\$data);

    return \$data;
};

sub tile_store {
# --------------------------------------------------
# Saves a single tile from OSM. Returns the raw PNG
# data.
#
    my ( $self, $tile_x, $tile_y, $zoom, $data_ref ) = @_;

# Check the cache if we have one
    CACHE_SAVE: {
        my $cache_path = $self->{cache_path} or last CACHE_SAVE;

        my $cache_fpath = "$cache_path/osm-$zoom-$tile_x-$tile_y.png";

        open my $fh, ">$cache_fpath" or last CACHE_SAVE;
        binmode $fh;
        print $fh $$data_ref;
        close $fh;
    };

    return $data_ref;

}

sub tile_coord {
# --------------------------------------------------
    my ( $self, $tile_x, $tile_y, $zoom ) = @_;
    my $lon = $tile_x / 2**$zoom * 360 - 180;
    my $n   = 3.14156 - ( 2 * 3.14156 * $tile_y ) / 2**$zoom;
    my $lat = 180/3.14156 * atan(.5*(exp($n)-exp(-$n)));
    return [ $lon, $lat, 0 ]; # return in coordinate format
}





1;
