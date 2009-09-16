package Geo::Graph::Overlay;

use strict;
use Geo::Graph::Base
    GEO_ATTRIBS => {
        data    => [],
        dataset => undef,
        range   => undef, # [0,0,0 => 0,0,0],
    };

sub data_load {
# --------------------------------------------------
# This associates a dataset with an overlay object.
# The input can be a file path, raw text, or another
# dataset itself.
#
    my ( $self, $data_in ) = @_;
    $data_in ||= $self->{dataset} or return;

# Now we try to figure out what sort of data this is
    LOAD: {
        if ( UNIVERSAL::isa( $data_in, 'Geo::Graph::Dataset' ) ) {
            last;
        }

# Load the data if available
# Assume the data is in GPX format
        require Geo::Graph::Dataset::GPX;
        $data_in = Geo::Graph::Dataset::GPX->load( $data_in ) or return;
    };

# Record the new dataset
    return $self->{dataset} = $data_in;
}

sub range {
# --------------------------------------------------
# This should be overriden by the subclass to return
# the maxium boundaries (range) that this overlay
# layer will take. Four parameters are returned
#
# 1. min latitude
# 2. min longitude
# 3. min altitude
# 4. max latitude
# 5. max longitude
# 6. max altitude
#
    my ( $self ) = shift;
    die ref($self)."::extent has not been defined yet.";
    return;
}

sub canvas_draw {
# --------------------------------------------------
    my ( $self ) = shift;
    die ref($self)."::canvas_draw has not been defined yet.";
    return;
}

1;
