package Geo::Graph::Datasource::Format::GPX;

# The format object is only really responsible
# for loading the dataset and tracking any 
# metadata that's associated with the GPX file

use strict;
use vars qw/ 
            $LOCAL_SELF 
            $LOCAL_DATASET 
            $LOCAL_TRACK 
            $LOCAL_TRACK_ENTRY
            $TAG_STACK 
        /;
use XML::Parser;
use Time::Local;
use Geo::Graph qw/:all/;
use constant {
        SIZEOF_f => length(pack("f",0)), # this is probably paranoia
        SIZEOF_L => length(pack("L",0)),
    };    
use Geo::Graph::Datasource::Format
    ISA => 'Geo::Graph::Datasource::Format';

sub load {
# --------------------------------------------------
# Convert the data into a format Geo::Graph recognizes.
#
    my ( $self, $data ) = @_;
    $data or return;

    ref $self or $self = $self->new;

# Now parse 'er
    my $parser = new XML::Parser(
                        Handlers => {
                                        Start => \&handle_start,
                                        End   => \&handle_end,
                                        Char  => \&handle_char
                                    }
                    );
    local $LOCAL_SELF        = $self;
    local $LOCAL_DATASET     = $self->{dataset};
    local $LOCAL_TRACK       = undef;
    local $LOCAL_TRACK_ENTRY = undef;
    local $TAG_STACK         = '';

# The parser's input for files and raw buffers is actually different.
# For file paths
    if ( -f $data ) { $parser->parsefile($data) }

# For parsing
    else { $parser->parse($data) }

    return $self;
}

sub handle_start {
# --------------------------------------------------
    my ( $expat, $e ) = splice @_, 0, 2;
    my %attrs = @_;

    $TAG_STACK = "$e/$TAG_STACK" ;

# Start of track
    if ( $TAG_STACK eq 'trk/gpx/' ) {
        $LOCAL_TRACK = [];
    }

# Handle individual track points
    elsif ( $TAG_STACK eq 'trkpt/trkseg/trk/gpx/' ) {
        push @$LOCAL_TRACK, $LOCAL_TRACK_ENTRY = [
            $attrs{lon},
            $attrs{lat},
            undef, # altitude
            undef, # timestamp
            {}
        ];
    }
}

sub handle_end {
# --------------------------------------------------
# End of tag handlers
#
    my ( $expat, $e ) = splice @_, 0, 2;

# If we just encountered the end of the track
    if ( $TAG_STACK eq 'trk/gpx/' ) {
        $LOCAL_DATASET->dataset_create(DATASET_TRACK => $LOCAL_TRACK);
    }

    substr( $TAG_STACK, 0, length($e)+1 ) = '';
}


sub handle_char {
# --------------------------------------------------
    my ( $expat, $s ) = splice @_, 0, 2;

    return 1 unless $s;

# Handle the track time for the particular point
    if ( $TAG_STACK eq 'time/trkpt/trkseg/trk/gpx/' ) {
        my @d = $s =~ /(\d+)/g;
        return unless @d == 6;
        return unless $d[0] > 1980;
        $d[0] -= 1900;
        $d[1] --;
        $LOCAL_TRACK_ENTRY->[REC_TIMESTAMP] = Time::Local::timegm(reverse @d);
    }
}

1;
