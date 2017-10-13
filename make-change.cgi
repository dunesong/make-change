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

my $due = $q->param('due');
$due = '' unless defined $due;
my $tendered = $q->param('tendered');
$tendered = '' unless defined $tendered;
my $mode = $q->param('mode');
$mode = 'html' unless defined $mode;

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
    print $q->header(-status => $http_status, -charset => 'utf-8')
        , $q->start_html(
            -title => 'Invalid Input Parameters'
            , -encoding => 'utf-8'
          )
        , $q->h1($http_status)
        , $q->p($change->{error})
        , $q->end_html
    ;
}
elsif($mode eq 'json') {
    print $q->header(-type => 'application/json', -charset => 'utf-8')
        , $change->to_json()
        , "\n"
    ;
}
else {
    my $results_div = '';
    if($due && $tendered) {
        $results_div = '<div class="row">';
        $results_div .= 'results go here';
        $results_div .= '</div>';
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
      <link rel="stylesheet" href="style.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.0/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
  </head>

  <body>
    <div class="container-fluid">
      <div class="row">
        <form action="make-change.cgi" class="form-inline">
          <div class="form-group">
            <label for="amount-due">Amount due:</label>
            <input type="number" id="amount-due" placeholder="Enter amount due" value="$due" class="form-control">
          </div>
          <div class="form-group">
            <label for="amount-tendered">Amount tendered:</label>
            <input type="number" id="amount-tendered" placeholder="Enter amount tendered" value="$tendered" class="form-control">
          </div>
          <button type="submit" class="btn btn-default">Make Change</button>
        </form>
        $results_div
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
