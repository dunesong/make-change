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
my $tendered = $q->param('tendered');
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
elsif(defined $change->{error}) {
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
