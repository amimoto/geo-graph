package Geo::Graph::Datasource;

use strict;
use vars qw/ $HAS_GPSBABEL $HANDLER_MAP $HANDLER_DEFAULT /;

$HANDLER_MAP = {
    gpx => 'Geo::Graph::Datasource::GPX',
};
$HANDLER_DEFAULT = 'Geo::Graph::Datasource::GPSBabel';
use Geo::Graph qw/ :constants /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        dataset         => undef,
        handler_map     => undef,
        handler_default => $HANDLER_DEFAULT,
    };

sub init {
# --------------------------------------------------
    my $self = shift;
    my $opts = $self->parameters( @_ );
    my $handler_map = {%$HANDLER_MAP};
    my $handler_map_new = $opts->{handler_map} ||= {};
    @$handler_map{keys %$handler_map_new} = values %$handler_map_new;
    $opts->{handler_map} = $handler_map;
    
    return $self->init_instance_attribs($opts);
}

sub load {
# --------------------------------------------------
# Attempt to do magic autoloading of the data provided.
# Since this is the base class, we do some sneaky stuff 
# by trying to autodetect what type of data we are working
# with and then dispatching it to the correct driver class.
# Note that this is just the trigger to convert the data 
# into a useable format for Geo::Graph. 
#
    my ( $self, $data ) = @_;

    ref $self or $self = $self->new;
    $data ||= $self->{data} or return;

    my $data_processor = '';
    LOAD_ATTEMPT : {

# Already converted?
        if ( ref $data ) {
            $data_processor = ref $self; # basically means "ignore me"
            last;
        }

# This is a path
        if ( 
            -f $data and 
            my $format = $self->fpath_format_detect( $data ) 
        ) {
            $data_processor = $self->{handler_map}{$format} || $self->{handler_default} || '';
            last;
        }

# Data has already been loaded, let's do the
# conversion as a string. Pass as ref to avoid making
# a copy of the text which may be big
        my $format = $self->string_format_detect( \$data ) or last;
        $data_processor = $self->{handler_map}{$format} || $self->{handler_default} || '';
    };

# Now we need to massage the code
    if ( $data_processor ne ref $self ) {
        $data_processor =~ /^\w+(::\w+)*$/ or return;
        eval "require $data_processor";
        $@ and die "Could not load $data_processor because $@"; # FIXME
        $data = $data_processor->load( $data );
    }

    return ( $self->{data} = $data );
}

sub string_format_detect {
# --------------------------------------------------
# Attempt to identify the GPS data via the headers
# in the string
#
    my ( $self, $data_ref ) = @_;
    my $header_buf = substr $$data_ref, 0, 1024;
    if ( $header_buf =~ m|http://www.topografix.com/GPX/1/0| ) {
        return 'gpx';
    }
    return;
}

sub fpath_format_detect {
# --------------------------------------------------
# Attempt to identify the GPS data via the pathname
# using extensions
#
    my ( $self, $fpath ) = @_;
    $fpath =~ /(\w+)$/ or return;
    my $ext = lc $1;
    if ( $ext eq 'gpx' ) {
        return $ext;
    };
    return;
}

1;
