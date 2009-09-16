#!/usr/bin/perl

use strict;

use Geo::Graph qw/:all/;
use Test::More 'no_plan';
use Math::Trig;

$ENV{GEO_GRAPH_CACHE_PATH} = "/home/aki/projects/cache";

my $geo;
eval { $geo = Geo::Graph->new() };
ok(!$@,"Loaded Geo::Graph okay <$@>");

# Load the data
require_ok('Geo::Graph::Dataset');
my $dataset;
eval{ $dataset = Geo::Graph::Dataset->load('t/02.sample.gpx') };
ok(!$@,"Dataset Loaded");

# Figure out the range velocities in the track
sub NESW { deg2rad($_[0]), deg2rad(90 - $_[1]) }
$dataset->iterator_reset;
my $prev_entry = $dataset->iterator_next;
my ( $v_min, $v_max ) = ( 100000000, -1 );
while ( my $entry = $dataset->iterator_next ) {
    my $d = Math::Trig::great_circle_distance(
                    NESW($prev_entry->[REC_LATITUDE], $prev_entry->[REC_LONGITUDE]),
                    NESW($entry->[REC_LATITUDE], $entry->[REC_LONGITUDE]),
                    6378
                );
    my $t = $entry->[REC_METADATA]{time_tics} - $prev_entry->[REC_METADATA]{time_tics};
    $prev_entry = $entry;
    next unless $t;
    my $v = $d/$t;

    if ( $v_min > $v ) {
        $v_min = $v;
    };

    if ( $v_max < $v ) {
        $v_max = $v;
    };
}

# $v_min holds the minimum velocity
# $v_max holds the maximum velocity

my $dataset_opts = {
    colour => sub {
    # --------------------------------------------------
        my ( $prev_entry, $entry, $canvas_obj ) = @_;

        my $d = Math::Trig::great_circle_distance(
                        NESW($prev_entry->[REC_LATITUDE], $prev_entry->[REC_LONGITUDE]),
                        NESW($entry->[REC_LATITUDE], $entry->[REC_LONGITUDE]),
                        6378
                    );
        my $t = $entry->[REC_METADATA]{time_tics} - $prev_entry->[REC_METADATA]{time_tics};
        $prev_entry = $entry;
        return [0,0,0] unless $t;
        my $v = $d/$t;

        my $ang = ($v/$v_max)*360;
        my $rgb = $canvas_obj->hsv_to_rgb($ang);

        return $rgb;
    }
};

# Create the overlay
eval{ $geo->overlay(SHAPE_TRACK,$dataset,$dataset_opts) };
ok(!$@,"Loaded Sample track okay <$@>");

# Render it
my $png;
eval{ $png = $geo->png };
ok(!$@,"PNG creation ran okay <$@>");
ok( ($png and !ref($png)), "PNG created" );

