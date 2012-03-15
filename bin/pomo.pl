#!/usr/bin/env perl
use strict;
use warnings;

use AnyEvent;

my $work = 25; # min
my $rest = 5; # min
my @conf = ($work, $rest);


my $cv = AnyEvent->condvar;
$cv->begin;

my $minute = 60; # second
my $count = 0;
my $p = 0;
my @timer = @conf;
my @bar = ("■", "# ");
my $bar = '';

my $sigint_w;
my $timer_w;


$sigint_w = AnyEvent->signal(
  signal => 'INT',
  cb => sub {
    warn "cleanup\n";
    undef $sigint_w;
    undef $timer_w;
    $cv->end;  
  },
);


$timer_w = AnyEvent->timer(
  interval => 1,
  cb => sub {
    system('clear');
    $count--;
    if ($count < 0) {
      $timer[$p] = $timer[$p] - 1;
      if ( $timer[$p] < 0) {
        $timer[$p] = $conf[$p]-1;
        $p = $p ? 0 : 1;
      }

      $count = $minute - 1;
      $bar = "$bar[$p]" x $timer[$p];
    }
    system(sprintf 'figlet %02d : %02d', $timer[$p], $count);
    printf qq{%s %02d:%02d\n}, $bar, $timer[$p], $count;
  },
);

$cv->recv;


