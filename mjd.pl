#!/usr/bin/perl

use Puzzle24;

$|=1;

my ($TARGET, $size) = @ARGV;
die unless defined $TARGET;

my $puzzle = Puzzle24->new({ target => $TARGET,
                             size => $size // 4,
#                             pool => [1,2,8,9],
                           });

while (1) {
  while (my $sol = $puzzle->one_solution) {
    print "(@{$puzzle->pool}) $sol->[0]\n";
  }
} continue {
  last unless $puzzle->bump;
}

