package Geo::Graph::Datasource::Format;

# The format object is only really responsible
# for loading the dataset and tracking any 
# metadata that's associated with any particular file

use strict;
use Geo::Graph::Dataset;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        dataset  => undef,
        metadata => {},
    };

sub new {
# --------------------------------------------------
    my $pkg = shift;

    my $self = $pkg->SUPER::new(@_);

# Create the dataset if required
    $self->{dataset} ||= Geo::Graph::Dataset->new;

    return $self;
}

sub load {
# --------------------------------------------------
# This method should return a dataset object.
# It must be noted that this does not return any
# file-specific metadata. 
#
    my ( $self, $data ) = @_;

# We expect an object...
    ref $self or $self = $self->new;

# Loading...
    LOAD_METHODS: {

# Is a reference? We assume string reference
        ref $data and $self->load_buffer($data)  or return;

# Points to a filepath?
         -f $data and $self->load_fpath($data)   or return;

# Assume data is a string
                      $self->load_buffer(\$data) or return;
    };

    return $self->{dataset};
}

sub load_fpath {
# --------------------------------------------------
# Load the data from the provided file path
#
    my ( $self, $fpath ) = @_;
    return unless -f $fpath;
    open my $fh, "<$fpath" or die "$!";
    local $/;
    my $buf = <$fh>;
    close $fh;
    return $self->load_buffer(\$buf);
}

sub load_buffer {
# --------------------------------------------------
# Loads the data from the provided buffer. Note that
# since the buffer can be large, we pass a buffer
# reference, we don't want to create a copy. That is
# up to the function writer to decide
#
    my ( $self, $buffer_ref ) = @_;
    die "Load buffer code has not been defined yet";
}

sub store_fpath {
# --------------------------------------------------
# Saves the dataset to the filepath provided
#
    die "Store fpath code has not been defined yet";
}

sub store_buffer {
# --------------------------------------------------
# Returns the dataset as a buffer
#
    die "Store buffer code has not been defined yet";
}

1;


