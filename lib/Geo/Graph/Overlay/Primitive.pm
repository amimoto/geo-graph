package Geo::Graph::Overlay::Primitive;

use strict;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        name              => undef, # if you want to name an overlay
        dataset_primitive => undef,
        range             => undef, # [0,0,0 => 0,0,0],
    };

sub data_load {
# --------------------------------------------------
# This associates a dataset with an overlay object.
# The input must be a dataset primitive 
#
    my ( $self, $data_in ) = @_;
    $data_in ||= $self->{dataset_primitive} or return;
    return $self->{dataset_primitive} = $data_in;
}

sub range {
# --------------------------------------------------
# This should be overriden by the subclass to return
# the maxium boundaries (range) that this overlay
# layer will take. Six parameters are returned
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
