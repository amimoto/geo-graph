package Geo::Graph::Canvas;

use strict;
use vars qw/ @ISA $AUTOLOAD /;
use GD;
use Geo::Graph qw/ :constants /;
use Geo::Graph::Mercator;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        gd_obj                 => undef,
        map_range              => undef,
        map_geometry           => undef,
        viewport_geometry      => undef,
    };

sub new {
# --------------------------------------------------
# Create the required canvas object. In this case,
# it'll be a GD object
#
    my $pkg = shift;
    my $self = $pkg->SUPER::new(@_);

# Sanity test
    return unless $self->{map_range} and $self->{map_geometry} and $self->{viewport_geometry};

# We now create the handler for the surface we're going to draw
# the map upon
    my $viewport_geometry = $self->{viewport_geometry};
    $self->{gd_obj} = GD::Image->new(
                            $viewport_geometry->[GEOMETRY_WIDTH],
                            $viewport_geometry->[GEOMETRY_HEIGHT],
                            1 # Turn truecolor on
                        );

    return $self;
}

sub png_overlay {
# --------------------------------------------------
# Places the provided png image in the correct location on the
# canvas based upon it's lat/lon coordinates.
#
    my ( $self, $png_data_ref, $tile_coords, $alpha, $scale  ) = @_;

    my $tile_img_obj = GD::Image->newFromPngData($$png_data_ref, 1 ) # truecolour is on
                        or return;
    my $w = $tile_img_obj->width  or return;
    my $h = $tile_img_obj->height or return;
    $scale ||= 1;

# Locate the X,Y location on the image we wish to localize the image to
    my $pixel_point = $self->coord_to_pixel($tile_coords);

# Now place the PNG
    $self->{gd_obj}->copyResized(
        $tile_img_obj,
        $pixel_point->[COORD_X],$pixel_point->[COORD_Y],
        0,0,
        $w, $h,
        int($w*$scale), int($h*$scale)
    );

    return 1;
}

sub line {
# --------------------------------------------------
# Draw a line between two coordinates
#
    my ( $self, $start, $end, $rgb ) = @_;

    $rgb ||= [0,0,0];
    my $gd_obj = $self->{gd_obj} or return;
    my $colour = $gd_obj->colorAllocate(@$rgb);

    my $start_pixel = $self->coord_to_pixel($start);
    my $end_pixel   = $self->coord_to_pixel($end);

    return $gd_obj->line(
        $start_pixel->[COORD_X],
        $start_pixel->[COORD_Y],
        $end_pixel->[COORD_X],
        $end_pixel->[COORD_Y],
        $colour
    );
}

sub circle {
# --------------------------------------------------
# Draw a small circle at the given coordinate
#
    my ( $self, $coord, $radius, $rgb ) = @_;

    $radius ||= 10;
    $rgb    ||= [255,255,255];

    my $gd_obj = $self->{gd_obj} or return;
    my $colour = $gd_obj->colorAllocate(@$rgb);

    my $center_pixel = $self->coord_to_pixel($coord);
    return $gd_obj->arc( 
        $center_pixel->[COORD_X],
        $center_pixel->[COORD_Y],
        $radius,
        $radius,
        0,360, # circle
        $colour
    );

}

sub coord_to_pixel {
# --------------------------------------------------
# Given a coordinate object, returns the x/y on
# the image that we should be looking at
#
    my ( $self, $coord ) = @_;
# TODO optimizations go here
    my $coord_pixel = wgs84_to_cartesian( $coord, $self->{map_geometry} );
    my $offset_x = $coord_pixel->[COORD_X] - $self->{viewport_geometry}[GEOMETRY_OFFSET_X];
    my $offset_y = $self->{viewport_geometry}[GEOMETRY_OFFSET_Y] - $coord_pixel->[COORD_Y] + $self->{viewport_geometry}[GEOMETRY_HEIGHT];
    return [ $offset_x, $offset_y ];
}

sub lat_pixel_resolution {
# --------------------------------------------------
# Returns latitudinal degrees a pixel spans
#
    my ( $self ) = @_;
    return $self->{map_geometry}[GEOMETRY_HEIGHT]/$self->{viewport_geometry}[GEOMETRY_HEIGHT];
}

sub lon_pixel_resolution {
# --------------------------------------------------
# Returns longitudinal degrees a pixel spans
#
    my ( $self ) = @_;
    return $self->{map_geometry}[GEOMETRY_WIDTH]/$self->{viewport_geometry}[GEOMETRY_WIDTH];
}

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

sub AUTOLOAD {
# --------------------------------------------------
    my $self = shift;
    my ($attrib) = $AUTOLOAD =~ /::([^:]+)$/;
    if ( my $gd_obj = $self->{gd_obj} ) {
        return $gd_obj->$attrib(@_) if $gd_obj->can($attrib);
    }
    return $self->SUPER::AUTOLOAD(@_);
};

1;
