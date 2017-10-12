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

1;
