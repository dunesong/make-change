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

$usd->make_change($due, $tendered);

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

# vim: set sw=4 ts=4 et:
