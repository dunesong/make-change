#!/usr/bin/env perl

use strict;
use warnings;

use 5.010;

use File::Basename qw/basename dirname/;
use Cwd qw/abs_path/;
use lib dirname(abs_path(__FILE__));

use MakeChange;

################################################################################

test_usage();

my($due, $tendered) = @ARGV;

my $usd = create_usd();

my $change = $usd->make_change($due, $tendered);

printf("\$%.2f change is due\n", $change->amount_due);
foreach my $currency (@{$change->currencies}) {
    my $descr = $currency->descr;
    $descr = $currency->descr_sing if $currency->amount == 1;

    printf("%d - %s\n", $currency->amount, $descr);
}

################################################################################

sub test_usage {
    my $PROGRAM = basename($0);
    my $USAGE = "usage: $PROGRAM amount_due amount_tendered";

    die "$USAGE\n" unless(scalar(@ARGV) == 2);
}

sub create_usd {
    return ChangeMaker->new(
        code => 'USD'
        , descr => 'United States Dollar'
        , currencies => [
            # in descending order
            Currency->new(
              value => 2000
              , descr => '$20 bills'
              , descr_sing => '$20 bill'
            )
            , Currency->new(
              value => 1000
              , descr => '$10 bills'
              , descr_sing => '$10 bill'
            )
            , Currency->new(
              value =>  500
              , descr => '$5 bills'
              , descr_sing => '$5 bill'
            )
            , Currency->new(
              value =>  100
              , descr => '$1 bills'
              , descr_sing => '$1 bill'
            )
            , Currency->new(
              value =>   25
              , descr => 'quarters'
              , descr_sing => 'quarter'
            )
            , Currency->new(
              value =>   10
              , descr => 'dimes'
              , descr_sing => 'dime'
            )
            , Currency->new(
              value =>    5
              , descr => 'nickels'
              , descr_sing => 'nickel'
            )
            , Currency->new(
              value =>    1
              , descr => 'pennies'
              , descr_sing => 'penny'
            )
        ]
    );
}

# vim: set sw=4 ts=4 et:
