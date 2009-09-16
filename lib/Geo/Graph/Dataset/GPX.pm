package Geo::Graph::Dataset::GPX;

use strict;
use vars qw/ $LOCAL_SELF @TS /;
use XML::Parser;
use Time::Local;
use Geo::Graph qw/:all/;
use constant {
        SIZEOF_f => length(pack("f",0)), # this is probably paranoia
        SIZEOF_L => length(pack("L",0)),
    };    
use Geo::Graph::Dataset
    ISA => 'Geo::Graph::Dataset',
    GEO_ATTRIBS => {
        entries                => 0,
        track_points           => '',
        track_points_elevation => '',
        track_points_time      => '',
    };

sub load {
# --------------------------------------------------
# Convert the data into a format Geo::Graph recognizes.
#
    my ( $self, $data ) = @_;

    ref $self or $self = $self->new;
    $data ||= $self->{data} or return;

# Now parse 'er
    my $parser = new XML::Parser(
                        Handlers => {
                                        Start => \&handle_start,
                                        End   => \&handle_end,
                                        Char  => \&handle_char
                                    }
                    );
    local $LOCAL_SELF = $self;
    local @TS;

# The parser's input for files and raw buffers is actually different.
# For file paths
    if ( -f $data ) { $parser->parsefile($data) }

# For parsing
    else { $parser->parse($data) }

# Once the parser has been called, the data should now be loaded into the 
# $self. It wouldn't seem so... but we have been using $LOCAL_SELF
# in the parser code to populate

# Initalize the section we want to use
    $self->section_select(0); # 0 is the first section

    return $self;
}

sub section_select {
# --------------------------------------------------
# Some data types may have multiple sections (eg multiple
# tracks in a GPX file. Account for this here) This 
# function will allow the user to choose between multiple 
# sections for iteration and analysis
#
    my ( $self, $section_index ) = @_;
    my $track_data = $self->{tracks}[$section_index] or return;
    $self->{track_active} = $track_data;
    if ( $self->{track_points_count} = length($track_data->{track_times}) / SIZEOF_L ) {
        $self->{track_start_tics} = unpack "L", $track_data->{track_times};
    }
    return $section_index;
}

sub handle_start {
# --------------------------------------------------
    my ( $expat, $e ) = splice @_, 0, 2;
    my %attrs = @_;
    unshift @TS, $e;
    my $path = join "/", @TS;

#    warn $path, "\n";
# Start of track
    if ( $path eq 'trk/gpx' ) {
        $LOCAL_SELF->{track_count}++;
        $LOCAL_SELF->{track_points}       = '';
        $LOCAL_SELF->{track_points_time}  = '';
        $LOCAL_SELF->{track_points_count} = 0;
    }

# Handle individual track points
    elsif ( $path eq 'trkpt/trkseg/trk/gpx' ) {
        $LOCAL_SELF->{track_points} .= pack "ff", $attrs{lat}, $attrs{lon};
        $LOCAL_SELF->{track_points_count}++;
    }
}

sub handle_end {
# --------------------------------------------------
    my ( $expat, $e ) = splice @_, 0, 2;
    my $path = join "/", @TS;
    shift @TS;

# End of track
    if ( $path eq 'trk/gpx' ) {
        push @{$LOCAL_SELF->{tracks}}, {
            track_points => delete $LOCAL_SELF->{track_points},
            track_times  => delete $LOCAL_SELF->{track_points_time},
            points       => delete $LOCAL_SELF->{track_points_count},
        };
    }
}


sub handle_char {
# --------------------------------------------------
    my ( $expat, $s ) = splice @_, 0, 2;

    return 1 unless $s;

    my $path = join "/", @TS;

# Handle the track time for the particular point
    if ( $path eq 'time/trkpt/trkseg/trk/gpx' ) {
        my @d = $s =~ /(\d+)/g;
        return unless @d == 6;
        return unless $d[0] > 1980;
        $d[0] -= 1900;
        $d[1] --;
        $LOCAL_SELF->{track_points_time} .= pack "L", Time::Local::timegm(reverse @d);
    }
}

sub entries {
# --------------------------------------------------
# Number of GPS points in the dataset
#
    my ( $self ) = @_;
    return $self->{track_points_count} || 0;
}

sub iterator_reset {
# --------------------------------------------------
# Moves the iterator index to the first entry in the
# list
#
    my ( $self ) = @_;
    $self->{iterator_index} = 0;
    return 1;
}

sub iterator_next {
# --------------------------------------------------
# Yields the record the iterator index is currently
# pointing to. Also increments the iterator index.
#
    my ( $self ) = @_;
    return unless my $track_active = $self->{track_active};
    return if $self->entries <= ( my $i = $self->{iterator_index}++ );

# Now figure out the lat, lon for the point
    my $points_offset = SIZEOF_f * $i;
    my $point_data    = substr( $self->{track_active}{track_points}, $points_offset * 2, SIZEOF_f * 2 );
    my ( $lat, $lon ) = unpack( "ff", $point_data );

# When was this point taken
    my $time_tics = 0;
    if ( $self->{track_active}{track_times} ) {
        my $time_data = substr( $self->{track_active}{track_times}, SIZEOF_L * $i, SIZEOF_L );
        if ( defined $time_data ) {
            $time_tics = unpack("L",$time_data);
        }
    }

# Now we can create the lat/lon/elevation record
    my $rec = [ $lon, $lat, 0, {} ];
    $time_tics and $rec->[REC_METADATA]{time_tics} = $time_tics;
    return $rec;
}

sub iterator_eof {
# --------------------------------------------------
# Returns a true value if the iterator index has reached
# the limit of the records in this dataset
#
    my ( $self ) = @_;
    return unless ref $self->{data} eq 'ARRAY';
    return $self->entries <= $self->{iterator_index};
}

1;
