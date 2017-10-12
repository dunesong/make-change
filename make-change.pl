#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw/basename/;
use Scalar::Util qw/looks_like_number/;
# Math::Currency would be preferrable but is unavailable
use Math::Round qw/round nearest_ceil/;

use 5.010;

my $PROGRAM = basename($0);
my $USAGE = "usage: $PROGRAM amount_due amount_tendered";

my @denominations = (
    # in descending order
      {cents => 2000, descr => '$20 bills'}
    , {cents => 1000, descr => '$10 bills'}
    , {cents =>  500, descr => '$5 bills'}
    , {cents =>  100, descr => '$1 bills'}
    , {cents =>   25, descr => 'quarters'}
    , {cents =>   10, descr => 'dimes'}
    , {cents =>    5, descr => 'nickels'}
    , {cents =>    1, descr => 'pennies'}
);

unless(scalar(@ARGV) == 2) { say $USAGE and exit 1; }

my($due, $tendered) = @ARGV;

test_input($due, $tendered);

# round in customer's favor when halfway between two choices
my $change = round(($tendered - $due) * 100);
printf("\$%.2f change is due\n", $change / 100);

my $remainder = $change;
foreach my $denomination (@denominations) {
    if(0 < $remainder && $denomination->{cents} <= $remainder) {
        printf(
            "%d x %s\n"
            , int($remainder / $denomination->{cents})
            , $denomination->{descr}
        );
        $remainder = $remainder % $denomination->{cents};
    }
}

################################################################################

sub test_input {
    my($due, $tendered) = (@_);

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
            "amount tendered ($tendered) must not be less than "
            . "amount due ($due)"
        );
    }
}

sub report_error {
    my($message) = (@_);
    my $PROGRAM = basename($0);

    say "$PROGRAM: $message";
    exit 1;
}

# vim: set sw=4 ts=4 et:
