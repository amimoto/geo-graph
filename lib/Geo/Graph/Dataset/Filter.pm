package Geo::Graph::Dataset::Filter;

use strict;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base';

sub filter {
# --------------------------------------------------
# Prototype function
#
    my ( $self ) = @_;
    die ref($self)."->filter has not been defined yet";
    return;
}

1;
