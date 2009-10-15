#!/usr/bin/perl

use strict;
use lib '../lib';
use Geo::Graph qw/:all/;
use Geo::Graph::Datasource;

my $fpath = shift @ARGV;

$ENV{GEO_GRAPH_CACHE_PATH} = "/home/aki/projects/cache";

my $ds = Geo::Graph::Datasource->load($fpath);
   $ds->filter( FILTER_CLEAN );

my $geo = Geo::Graph->new;
   $geo->load($ds);
my $png = $geo->png;

open F, ">out.png";
binmode F;
print F $png;
close F;
