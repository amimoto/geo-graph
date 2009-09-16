# ==================================================================
#
#   Geo::Graph::Language
#   Author: Aki Mimoto
#   $Id$
#
# ==================================================================
#
# Description: 
#

package Geo::Graph::Language;
# ==================================================================

use strict;
use vars qw/
        $GEO_LOCALE 
        $GEO_LOCALE_PATH
        $GEO_LOCALE_MESSAGES 
    /;
use Geo::Graph::Base
    ISA => 'Geo::Graph::Base',
    GEO_ATTRIBS => {
        messages => {},
    };

$GEO_LOCALE_MESSAGES = {
};
$GEO_LOCALE = 'en';
$GEO_LOCALE_PATH = '.';

sub numbers {
# --------------------------------------------------
}

sub date {
# --------------------------------------------------
}

sub language {
# --------------------------------------------------
    my $self = shift;

    my $messages = $GEO_LOCALE_MESSAGES->{$GEO_LOCALE} ||= do {
        my $target_fpath = "$GEO_LOCALE_PATH/$GEO_LOCALE.txt";

        my $m;
        require Symbol;
        my $fh = Symbol::gensym();

        if ( -f $target_fpath ) {
            open $fh, "<$target_fpath" or die $!;
        }
        else {
            $fh = \*DATA;
        }

        while ( my $l = <$fh>  ) {
            next if $l =~ /^\s*$/;
            $l =~ /([^\s]*)\s+(.*)/;
            ( $m ||= {} )->{$1} = $2;
        }
        close $fh;

        $m;
    };

# This will parse messages coming through such that it will
# be possible to encode a language string with a code in the
# following formats:
#
#      ->language( "CODE", $parametrs ...  )
#      ->language( "CODE:Default Message %s", $parametrs ...  )
#
    my $message = shift or return;
    $message    =~ s/^([\w_]+)\s*:?\s*//;
    my $key     = $1;
    my $message_template;

# Get the message template in the following order:
#   1. The local object if available 
#   2. The global message object
#   3. The provided default message
#
    ref $self and $message_template = $self->{messages}{$key};
    $message_template ||= $messages->{$key} || $message;

    return sprintf( $message_template, @_ );
}

1;

__DATA__
GEO__unhandled        Unhandled attribute '%s' called
GEO__unknown          Unknown/Unhandled error encountered: %s

GEO__separator , 

