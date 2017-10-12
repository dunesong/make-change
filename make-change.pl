#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw/basename/;
use Scalar::Util qw/looks_like_number/;
# Math::Currency would be preferrable but is unavailable
use Math::Round qw/nearest_ceil/;

use 5.010;

my $PROGRAM = basename($0);
my $USAGE = "usage: $PROGRAM amount_due amount_tendered";

my $smallest_denomination = 0.01;

unless(scalar(@ARGV) == 2) { say $USAGE and exit 1; }

my($due, $tendered) = @ARGV;

unless(looks_like_number($due)) { 
    report_error("amount due ($due) is not a number");
}
unless(looks_like_number($tendered)) { 
    report_error("amount tendered ($tendered) is not a number");
}
unless($due >= 0) {
    report_error("amount due ($due) must be non-negative");
}
unless($tendered >= 0) {
    report_error("amount tendered ($tendered) must be non-negative");
}
unless($tendered >= $due) {
    report_error(
        "amount tendered ($tendered) must not be less than amount due ($due)"
    );
}

# round in customer's favor when halfway between two choices
say nearest_ceil($smallest_denomination, $tendered - $due);

################################################################################

sub report_error {
    my($message) = (@_);
    my $PROGRAM = basename($0);

    say "$PROGRAM: $message";
    exit 1;
}

# vim: set sw=4 ts=4 et:
