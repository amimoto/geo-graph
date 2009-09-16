package Geo::Graph::Mercator;

use strict;
use Exporter;
use Geo::Graph qw/ :constants /;
use Math::Trig;
use vars qw/ @ISA @EXPORT $PI /;

@ISA = 'Exporter';

@EXPORT = qw( coord_to_pixels pixels_to_coord );
$PI = 3.14159290045661;

sub coord_to_pixels {
# --------------------------------------------------
# Given Lat/Lon coordinates, returns an x,y pair where
# x and y range between 0 and 1, unless image geometry
# is provided.
#
    my ( $geo_coord, $image_geometry ) = @_;

# Figure out the extents we're playing with
    $image_geometry ||= [1,1];
    my $width  = $image_geometry->[GEOMETRY_WIDTH];
    my $height = $image_geometry->[GEOMETRY_HEIGHT];

# Now do the transformation...
# X is easy
    my $x      = $width * ( $geo_coord->[COORD_LON] + 180 ) / 360;

# Y gets complicated. Not only is there the transformation, 
# but when using GD, the upper left hand corner is 0,0, not 
# the center!
    my $lat_radians = deg2rad($geo_coord->[COORD_LAT]);
    my $y      = ( log(tan($lat_radians)+sec($lat_radians)) / ( $PI * 2 ) + .5 ) * $height;

# Done!
    return [$x,$y];
}

sub pixels_to_coord {
# --------------------------------------------------
# Given an x,y pair, where x and y range between 0 and 1
# returns a lat/long coordinate
#
    my ( $image_coord, $image_geometry ) = @_;

# Figure out the extents we're playing with
    $image_geometry ||= [1,1];
    my $width  = $image_geometry->[GEOMETRY_WIDTH];
    my $height = $image_geometry->[GEOMETRY_HEIGHT];

# Now do the transformation...
# Longitude is easy
    my $lon    = $image_coord->[COORD_X] * 360 / $width - 180;

# Latitude is hard!
    my $lat    = rad2deg(atan(sinh( - $PI * ( 1-2*$image_coord->[COORD_Y]/$height ) )));

# Done!
    return [$lat,$lon];

}

1;
