package Geo::Graph::Utils;

use strict;
use Exporter;
use Geo::Graph qw/ :constants /;
use Math::Trig;
use vars qw/ @ISA @EXPORT $PI $VERSION /;
$VERSION = '0.01';

@ISA = 'Exporter';

@EXPORT = qw( 
                distance
                coord_deg_to_rad   coord_rad_to_deg
                wgs84_to_cartesian cartesian_to_wgs84 
            );
$PI = 3.14159290045661;

##################################################
## Distance calculator
##################################################

sub distance {
# --------------------------------------------------
# Returns the distance between two coordinates, in meters
# Uses the great-circle equation
#
    my ( $coord_a, $coord_b ) = @_;

# Since these equations assume radians...
    my $cra = coord_deg_to_rad($coord_a);
    my $crb = coord_deg_to_rad($coord_b);

    my $a = sin(($crb->[COORD_LAT]-$cra->[COORD_LAT])/2.0);
    my $b = sin(($crb->[COORD_LON]-$cra->[COORD_LON])/2.0);
    my $h = $a**2 + cos($cra->[COORD_LAT]) * cos($crb->[COORD_LAT]) * $b**2;
    my $distance = 2 * asin(sqrt($h)) * EARTH_RADIUS; # distance in meters

    return $distance;
}

##################################################
## Conversion and projection equations
##################################################

sub coord_deg_to_rad ($;$) {
# --------------------------------------------------
# Converts degrees based coordinates to radians
# based coordinates
#
    my ( $geo_coord ) = @_;
    my $rad_coord = [
        deg2rad($geo_coord->[COORD_LON]),
        deg2rad($geo_coord->[COORD_LAT])
    ];
    return $rad_coord;
}

sub coord_rad_to_deg ($;$) {
# --------------------------------------------------
# Converts degrees based coordinates to radians
# based coordinates
#
    my ( $rad_coord ) = @_;
    my $geo_coord = [
        deg2rad($rad_coord->[COORD_LON]),
        deg2rad($rad_coord->[COORD_LAT])
    ];
    return $geo_coord;
}

sub wgs84_to_cartesian ($;$){
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

sub cartesian_to_wgs84 ($;$) {
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
    return [$lon,$lat];

}


##################################################
## Colour mapping calculations
##################################################

sub hsv_to_rgb {
# --------------------------------------------------
# Turns hue-saturation-value to rgb
# $h float 0-360 [?] Degrees on the HSV wheel
# $s float 0-1   [1] Saturation
# $v float 0-1   [1] Value
# $m float 0>    [255] Maxmimum individual RGB channel value
#
    my ($h,$s,$v,$m) = @_;

    defined $v or $v = 1;
    defined $s or $s = 1;
    defined $m or $m = 255;
    my $hi    = int($h); # int = floor
    my $fract = $h - $hi;
    my $min   = $m * (1-$s);
    my $delta = $m - $min;

# Create the base offsets for individual colours
    my $r = ( ( $hi + 120 ) % 360 ) + $fract;
    my $g =   ( $hi % 360 ) + $fract;
    my $b = ( ( $hi - 120 + 360 ) % 360 ) + $fract;

# Find out what hue the colour is and apply the saturation/value modifiers
    my @rgb = map {
                my $c = $_ <= 60  ? ( $_ / 60 * $delta + $min  ):
                        $_ <= 180 ? $m :
                        $_ <= 240 ? ( ( 240 - $_ ) / 60 ) * $delta + $min
                                  : $min;
                $c * $v;
            } ( $r, $g, $b );

    return \@rgb;
}

1;
