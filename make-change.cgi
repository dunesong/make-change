#!/usr/bin/perl -w

use strict;
use warnings;

use File::Basename qw/basename dirname/;
use Cwd qw/abs_path/;
use lib dirname(abs_path(__FILE__));

use CGI;
use MakeChange;

################################################################################

my $q = CGI->new;

my $usd = create_usd();
my $due = '';
my $tendered = '';
my $mode = 'html';

$due = strip_non_numeric($q->param('due'))
    if(defined $q->param('due'));
$tendered = strip_non_numeric($q->param('tendered'))
    if(defined $q->param('tendered'));
$mode = $q->param('mode')
    if(defined $q->param('mode'));

my $change = $usd->make_change($due, $tendered);

################################################################################

if($q->cgi_error) {
    print $q->header(-status => $q->cgi_error, -charset => 'utf-8')
        , $q->start_html(
            -title => 'CGI Error'
            , -encoding => 'utf-8'
          )
        , $q->h1($q->cgi_error)
        , $q->end_html
    ;
}
elsif($mode eq 'json' && defined $change->{error}) {
    my $http_status = '400 Bad Request (invalid input parameters)';
    print $q->header(
            -type => 'application/json'
            , -status => $http_status
            , -charset => 'utf-8'
        )
        , $change->to_json()
        , "\n"
    ;
}
elsif($mode eq 'json') {
    print $q->header(-type => 'application/json', -charset => 'utf-8')
        , $change->to_json()
        , "\n"
    ;
}
else {
    my $cgi_path = $q->url(-absolute => 1);

    my $results_div = '';
    if($due ne '' || $tendered ne '') {
        if(defined $change->error) {
            $results_div .= '<p class="alert alert-danger">';
            $results_div .= '<strong>Error:</strong> ';
            $results_div .= $change->error;
            $results_div .= '</p>';
        }
        else {
            $results_div .= '<table class="table table-striped"><tbody>';
            $results_div .= '<tr scope="row" class="info">';
            $results_div .= '<th>Change Amount</th><td>';
            if($change->amount_due || 0 == $change->amount_due) {
                $results_div .= sprintf('$%.2f', $change->amount_due);
            }
            $results_div .= '</td></tr>';
            if(scalar(@{$change->currencies}) > 0) {
                $results_div .= '<tr>'
                  . '<th scope="col" id="quantity-header">Quantity</th>'
                  . '<th scope="col">Currency</th></tr>';
                foreach my $currency (@{$change->currencies}) {
                    $results_div .= '<tr><td align="right">';
                    $results_div .= $currency->amount;
                    $results_div .= ' &times;</td><td>';
                    if($currency->amount > 1) {
                        $results_div .= $currency->descr;
                    }
                    else {
                        $results_div .= $currency->descr_sing;
                    }
                    $results_div .= '</td></tr>';
                }
            }
            $results_div .= '</tbody></table>';
        }
    }


    print $q->header(-charset => 'utf-8');
    print <<"HTML_FORM";
<!doctype html>

<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Make Change</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="make change based on amount due and amount tendered">
    <meta name="author" content="jonathan\@dunesong.com">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <link rel="stylesheet" href="style/style.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.0/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script src="scripts/ajax.js"></script>
  </head>

  <body>
    <div class="container-fluid">
      <div class="row">
        <div class="col-sm-4"></div>
        <form action="$cgi_path" method="get" id="change-form" class="col-sm-4">
          <div class="form-group">
            <label for="due">Amount due:</label>
            <input type="number" min="0" step="0.01" id="due" name="due" placeholder="Enter amount due" value="$due" class="form-control">
          </div>
          <div class="form-group">
            <label for="tendered">Amount tendered:</label>
            <input type="number" min="0" step="0.01" id="tendered" name="tendered" placeholder="Enter amount tendered" value="$tendered" class="form-control">
          </div>
          <button type="submit" class="btn btn-default">Make Change</button>
        </form>
        <div class="col-sm-4"></div>
      </div>
      <div class="row">
        <div class="col-sm-4"></div>
        <div id="results" class="col-sm-4">
          $results_div
        </div>
        <div class="col-sm-4"></div>
      </div>
    </div>
  </body>
</html>
HTML_FORM
}

exit 0;

################################################################################

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

sub strip_non_numeric {
    my($s) = @_;

    $s =~ s/[^[:digit:].]//g;
    return $s;
}

# vim: set sw=4 ts=4 et:
