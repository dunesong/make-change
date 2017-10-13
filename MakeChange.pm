################################################################################
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

sub to_json {
    my($self) = @_;

    my $json = '{';
    if($self->amount) {
        $json .= sprintf('"amount": %d', $self->amount);
    }
    if($self->value) {
        $json .= sprintf(', "value": %d', $self->value);
    }
    if($self->descr) {
        $json .= sprintf(', "descr": "%s"', $self->descr);
    }
    $json .= '}';
}


################################################################################
# The ChangeDue class models the amount of change due.
################################################################################

package ChangeDue;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'ArrayRefOfCurrencyAmounts'
    => as 'ArrayRef[CurrencyAmount]'
;

coerce 'ArrayRefOfCurrencyAmounts', from 'CurrencyAmount', via { [$_] };

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

sub to_json {
    my($self) = @_;

    my $json = '{';
    if($self->amount_due) {
        $json .= sprintf('"amount_due": %.2f', $self->amount_due);
    }
    if($self->error) {
        $json .= sprintf(', "error": %s', $self->error);
    }
    if($self->currencies) {
        $json .= ', "currencies":[';
        foreach my $currency (@{$self->currencies}) {
            $json .= $currency->to_json()
        }
        $json .= ']';
    }
    $json .= '}';
}

################################################################################
# The MoneySystem class models a collection of physical currencies that make
# up a national currency (e.g. the US Dollar, the Japanese Yen).
################################################################################

package MoneySystem;

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
use Math::Round qw/round nearest/;
use Carp qw/croak confess/;

has 'max_value' => (
    # more US dollars than are in the M0 cash supply
    is => 'ro'
    , isa => 'Int'
    , default => 2000000000000
);

has 'max_length' => (
    is => 'ro'
    , isa => 'Int'
    , default => 16
);

sub make_change {
    my ($self, $due, $tendered) = @_;

    unless(length($due) < $self->max_length) {
        return ChangeDue->new(
            error => 'amount due exceeds the maximum argument length ('
                . $self->max_length
                . ' characters)'
        );
    }

    unless(length($tendered) < $self->max_length) {
        return ChangeDue->new(
            error => 'amount tendered exceeds the maximum argument length ('
                . $self->max_length
                . ' characters)'
        );
    }

    unless(looks_like_number($due)) {
        return ChangeDue->new(error => 'amount due is not a number');
    }

    unless(looks_like_number($tendered)) {
        return ChangeDue->new(
            error => 'amount tendered is not a number'
        );
    }

    unless($due < $self->max_value) {
        return ChangeDue->new(
            error => 'amount due exceeds the maximum value ('
                . $self->max_value
                . ')'
        );
    }

    unless($tendered < $self->max_value) {
        return ChangeDue->new(
            error => 'amount tendered exceeds the maximum value ('
                . $self->max_value
                . ')'
        );
    }

    unless($due >= 0) {
        return ChangeDue->new(error => 'amount due must be non-negative');
    }

    unless($tendered >= 0) {
        return ChangeDue->new(error => 'amount tendered must be non-negative');
    }

    unless($tendered >= $due) {
        return ChangeDue->new(
            error => 'amount tendered must not be less than amount due'
        );
    }

    my $change = ChangeDue->new();

    $change->amount_due(nearest(0.01, $tendered - $due));

    # round in customer's favor when halfway between two choices
    # e.g. if due = 4.995 and tendered = 10.00, provide 5.01 in change
    my $remainder = round(100 * $change->amount_due);

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
