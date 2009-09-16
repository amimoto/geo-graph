#!/usr/bin/perl

use strict;
use lib '../lib';

use Getopt::Long;
use Pod::Usage;
use vars qw/ @OPTIONS %OPTS /;
$|++;

@OPTIONS = (
    'h|help'     => \$OPTS{help},
    'o|of=s'     => \$OPTS{out_fpath},
    'l|log=s'    => \$OPTS{log_fpath},
    'i|identify' => \$OPTS{identify},
    'p|port=s'   => \$OPTS{port},
    'q|quiet'    => \$OPTS{quiet},
    'man'        => \$OPTS{man},
);


my $ret = Getopt::Long::GetOptionsFromArray(\@ARGV,@OPTIONS) or pod2usage(2);
pod2usage() if $OPTS{help};
pod2usage(-exitstatus => 0, -verbose => 2) if $OPTS{man};

main(\%OPTS);

sub main {
# --------------------------------------------------
    my $opts = shift;

# Now do magic!
    require Geo::Graph;
    my $gg = Geo::Graph->new($opts);

# Try and make the output file right away
    my $out_fpath = $opts->{out_fpath} || do {
                        my @d = localtime;
                        $d[4]++;
                        $d[5]+=1900;
                        my $fname = sprintf '%i-%02i-%02i_%02i:%02i:%02i.png', reverse @d[0..5];
                        $fname;
                    };

    open F, ">$out_fpath" or die "Could not make output file '$out_fpath' because '$!'";
    binmode F;

# And download the data
    require Geo::Graph;


# Done!
    print " - Done\n";
}

__END__

=head1 NAME

map.pl - Render a GPX track onto OSM/GoogleMap tiles

=head1 SYNOPSIS

 map.pl [options] 

 Options:

  -h, --help             brief help message
  --man                  full documentation
  -o FILE, --of FILE     dump file for data
  -l FILE, --log FILE    log path for IO
  -p PATH, --port PATH   path to port
  -q, --quiet            silence output except errors

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut


