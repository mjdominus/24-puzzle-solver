#!/usr/bin/perl

use Puzzle24;

$|=1;


my (@pool) = @ARGV;

my $puzzle = Puzzle24->new({ target => 24,
                             pool => \@pool,
                           });

while (my $sol = $puzzle->one_solution) {
    print "$sol->[0]\n";
}
