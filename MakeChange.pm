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
# The CurrencyAmount class models the amount of a particular currency.
################################################################################

package CurrencyAmount;

use Moose;

extends 'Currency';

has 'amount' => (
    is => 'rw'
    , isa => 'Int'
);


################################################################################
# The ChangeDue class models the amount of change due.
################################################################################

package ChangeDue;

use Moose;

has 'currencies' => (
    is => 'rw'
    , isa => 'ArrayRefOfCurrencyAmounts'
    , default => sub{ [] }
);

has 'amount_due' => (
    is => 'rw'
    , isa => 'Num'
);

has 'error' => (
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
    , default => sub{ [] }
);


################################################################################
# The ChangeMaker class encapsulates the ability to make change.
################################################################################

package ChangeMaker;

use Moose;

extends 'MoneySystem';

use Scalar::Util qw/looks_like_number/;
# Math::Currency would be preferrable to Math::Round but is unavailable
use Math::Round qw/round/;
use Carp qw/croak confess/;

sub make_change {
    my ($self, $due, $tendered) = @_;

    unless(looks_like_number($due)) {
        return ChangeDue->new(error => "amount due ($due) is not a number");
    }
    
    unless(looks_like_number($tendered)) { 
        return ChangeDue->new(
            error => "amount tendered ($tendered) is not a number"
        );
    }

    unless($due >= 0) {
        return ChangeDue->new(
            error => "amount due ($due) must be non-negative"
        );
    }

    unless($tendered >= 0) {
        return ChangeDue->new(
            error => "amount tendered ($tendered) must be non-negative"
        );
    }

    unless($tendered >= $due) {
        return ChangeDue->new(
            error => "amount tendered ($tendered) must not be less than "
                     . "amount due ($due)"
        );
    }

    my $change = ChangeDue->new();

    # round in customer's favor when halfway between two choices
    $change->amount_due(round(($tendered - $due) * 100));

    my $remainder = $change->amount_due;

    # ensure that the currencies are in reverse sort order based on the value
    my @sorted_currencies = 
        sort {$b->{value} <=> $a->{value}} @{$self->{currencies}};

    foreach my $currency (@sorted_currencies) {
        if(0 < $remainder && $currency->{value} <= $remainder) {
            push(@{$change->currencies}, CurrencyAmount->new(
                amount => int($remainder / $currency->{value})
                , value => $currency->value
                , descr => $currency->descr
            ));
            $remainder = $remainder % $currency->{value};
        }
    }

    return $change;
}

################################################################################

1;

# vim: set sw=4 ts=4 et:
