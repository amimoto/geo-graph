#!/usr/bin/perl

use strict;
use lib '../lib';
use Geo::Graph qw/:all/;

my $fpath = shift @ARGV;

$ENV{GEO_GRAPH_CACHE_PATH} = "/home/aki/projects/cache";

my $geo = Geo::Graph->new;
$geo->overlay(SHAPE_TRACK,$fpath);
my $png = $geo->png;

open F, ">out.png";
binmode F;
print F $png;
close F;
