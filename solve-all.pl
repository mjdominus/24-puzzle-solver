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
  my $pool = join "", @{$puzzle->pool};
  my @sols;
  while (my $sol = $puzzle->solver->solve) {
    push @sols, $sol->to_string;
  }
  print $pool, ",", 0+@sols, ",", join(";" => @sols), "\n" if @sols;
} continue {
  last unless $puzzle->bump;
}

