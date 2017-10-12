#!/usr/bin/env perl

use strict;
use warnings;

use 5.010;

use File::Basename qw/basename dirname/;
use Cwd qw/abs_path/;
use lib dirname(abs_path(__FILE__));

use Scalar::Util qw/looks_like_number/;
# Math::Currency would be preferrable to Math::Round but is unavailable
use Math::Round qw/round nearest_ceil/;

use MakeChange;

################################################################################

test_usage();

my($due, $tendered) = @ARGV;

test_input($due, $tendered);

# round in customer's favor when halfway between two choices
my $change = round(($tendered - $due) * 100);

printf("\$%.2f change is due\n", $change / 100);

my $usd = create_usd();
my $remainder = $change;
foreach my $currency (@{$usd->currencies}) {
    if(0 < $remainder && $currency->{value} <= $remainder) {
        printf(
            "%d x %s\n"
            , int($remainder / $currency->{value})
            , $currency->{descr}
        );
        $remainder = $remainder % $currency->{value};
    }
}

################################################################################

sub test_usage {
    my $PROGRAM = basename($0);
    my $USAGE = "usage: $PROGRAM amount_due amount_tendered";

    die "$USAGE\n" unless(scalar(@ARGV) == 2);
}

sub test_input {
    my($due, $tendered) = @_;

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

sub create_usd {
    return MoneySystem->new(
        code => 'USD'
        , descr => 'United States Dollar'
        , currencies => [
            # in descending order
              Currency->new(value => 2000, descr => '$20 bills')
            , Currency->new(value => 1000, descr => '$10 bills')
            , Currency->new(value =>  500, descr => '$5 bills')
            , Currency->new(value =>  100, descr => '$1 bills')
            , Currency->new(value =>   25, descr => 'quarters')
            , Currency->new(value =>   10, descr => 'dimes')
            , Currency->new(value =>    5, descr => 'nickels')
            , Currency->new(value =>    1, descr => 'pennies')
        ]
    );
}

sub report_error {
    my($message) = @_;
    my $PROGRAM = basename($0);

    die "$PROGRAM: $message\n";
}

# vim: set sw=4 ts=4 et:
