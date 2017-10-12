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
use Moose::Util::TypeConstraints;

subtype 'CurrencyCode'
    # an ISO 4217 currency code (e.g. 'USD', 'JPY')
    => as 'Str'
    => where {/[A-Z]{3}/};

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

subtype 'ArrayRefOfCurrencies'
    => as 'ArrayRef[Currency]';

coerce 'ArrayRefOfCurrencies', from 'Currency', via { [$_] };

has 'currencies' => (
    is => 'rw'
    , isa => 'ArrayRefOfCurrencies'
);

1;

# vim: set sw=4 ts=4 et:
