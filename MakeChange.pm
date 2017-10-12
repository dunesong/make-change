################################################################################
# The ChangeTypes package collects the simple data types used in the other
# classes.
################################################################################

package ChangeTypes;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'CurrencyCode'
    # an ISO 4217 currency code (e.g. 'USD', 'JPY')
    , as 'Str'
    , where {/[A-Z]{3}/}
;

subtype 'ArrayRefOfCurrencies'
    => as 'ArrayRef[Currency]'
;
coerce 'ArrayRefOfCurrencies', from 'Currency', via { [$_] };

subtype 'ArrayRefOfCurrencyAmounts'
    => as 'ArrayRef[CurrencyAmount]'
;
coerce 'ArrayRefOfCurrencyAmounts', from 'CurrencyAmount', via { [$_] };


################################################################################
# The Currency class models a type of physical currency (i.e. a banknote 
# or coin.
################################################################################

package Currency;

use Moose;

has 'value' => (
    # the currency's value in cents
    is => 'rw'
    , isa => 'Int'
    , required => 1
    , default => 1
);

has 'descr' => (
    # human-friendly description
    is => 'rw'
    , isa => 'Str'
);


################################################################################
# The MoneySystem class models a collection of physical currencies that make
# up a national currency (e.g. the US Dollar, the Japanese Yen).
################################################################################

package MoneySystem;

use Moose;
use ChangeTypes;

has 'code' => (
    is => 'rw'
    , isa => 'CurrencyCode'
    , required => 1
    , default => 'USD'
);

has 'descr' => (
    # human-friendly description
    is => 'rw'
    , isa => 'Str'
);

has 'currencies' => (
    is => 'rw'
    , isa => 'ArrayRefOfCurrencies'
);


################################################################################
# The CurrencyAmount class models the amount of change due.
################################################################################

package CurrencyAmount;

use Moose;

extends 'Currency';

has 'amount' => (
    is => 'rw'
    , isa => 'Int'
);


################################################################################
# The ChangeMaker class encapsulates the ability to make change.
################################################################################

package ChangeMaker;

use Moose;

extends 'MoneySystem';

use Scalar::Util qw/looks_like_number/;
# Math::Currency would be preferrable to Math::Round but is unavailable
use Math::Round qw/round nearest_ceil/;
use Carp qw/croak confess/;

has 'currency_due' => (
    is => 'rw'
    , isa => 'ArrayRefOfCurrencyAmounts'
);

sub make_change {
    my ($self, $due, $tendered) = @_;

    croak "amount due ($due) is not a number"
        unless(looks_like_number($due));
    
    croak "amount tendered ($tendered) is not a number"
        unless(looks_like_number($tendered)); 

    croak "amount due ($due) must be non-negative"
        unless($due >= 0);

    croak "amount tendered ($tendered) must be non-negative"
        unless($tendered >= 0);

    croak "amount tendered ($tendered) must not be less than amount due ($due)"
        unless($tendered >= $due);

    # round in customer's favor when halfway between two choices
    my $change = round(($tendered - $due) * 100);

    printf("\$%.2f change is due\n", $change / 100);

    my $remainder = $change;
    foreach my $currency (@{$self->currencies}) {
        if(0 < $remainder && $currency->{value} <= $remainder) {
            printf(
                "%d x %s\n"
                , int($remainder / $currency->{value})
                , $currency->{descr}
            );
            $remainder = $remainder % $currency->{value};
        }
    }
}

################################################################################

1;

# vim: set sw=4 ts=4 et:
