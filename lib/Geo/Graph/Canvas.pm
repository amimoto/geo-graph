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

# Now we need to calculate where the viewport needs to go if it hasn't
# been defined yet
    if ( defined $viewport_geometry->[GEOMETRY_OFFSET_X] ) {
        my $center_coord = Geo::Graph->range_center( $self->{map_range} );
        my $center_pixel = coord_to_pixels( $center_coord, $self->{map_geometry} );
        $viewport_geometry->[GEOMETRY_OFFSET_X] = $center_pixel->[COORD_X] - int($viewport_geometry->[GEOMETRY_WIDTH]  / 2);
        $viewport_geometry->[GEOMETRY_OFFSET_Y] = $center_pixel->[COORD_Y] - int($viewport_geometry->[GEOMETRY_HEIGHT] / 2);
    };

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

warn "$tile_coords->[0],$tile_coords->[1] => $pixel_point->[0],$pixel_point->[1]\n";

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

    warn "Mapping from: $start->[1],$start->[0] to $end->[1],$end->[0]\n";

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

    $radius ||= 6;
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
    my $coord_pixel = coord_to_pixels( $coord, $self->{map_geometry} );
    my $offset_x = $coord_pixel->[COORD_X] - $self->{viewport_geometry}[GEOMETRY_OFFSET_X];
    my $offset_y = $coord_pixel->[COORD_Y] - $self->{viewport_geometry}[GEOMETRY_OFFSET_Y];
    return [ $offset_x, $offset_y ];
}

sub lat_pixel_resolution {
# --------------------------------------------------
# Returns latitudinal degrees a pixel spans
#
    my ( $self ) = @_;

    warn "\n$self->{map_geometry}[GEOMETRY_OFFSET_Y],$self->{map_geometry}[GEOMETRY_OFFSET_X]\n".
    ( 
      ($self->{map_geometry}[GEOMETRY_OFFSET_Y]+$self->{map_geometry}[GEOMETRY_HEIGHT])  .",".
      ($self->{map_geometry}[GEOMETRY_OFFSET_X]+$self->{map_geometry}[GEOMETRY_WIDTH]) 
    )."\n";

    return $self->{map_geometry}[GEOMETRY_HEIGHT]/$self->{viewport_geometry}[GEOMETRY_HEIGHT];
}

sub lon_pixel_resolution {
# --------------------------------------------------
# Returns longitudinal degrees a pixel spans
#
    my ( $self ) = @_;
    return $self->{map_geometry}[GEOMETRY_WIDTH]/$self->{viewport_geometry}[GEOMETRY_WIDTH];
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
