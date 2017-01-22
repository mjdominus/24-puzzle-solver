#!/usr/bin/perl

use Puzzle24;

$|=1;


my ($TARGET, @pool) = @ARGV;

my $solver = Puzzle24->new({ target => $TARGET,
                             pool => \@pool,
                           })->solver;

my %seen;
my $letter = "A";
while (my $sol = $solver->solve) {
    my $expr = $sol->[0];
#    printf "## %s\n", $expr->to_string;
    my $id_string = $expr->id_string;
    $seen{$id_string} //= $letter++;
    printf "%1s %30s %30s\n", $seen{$id_string}, $expr->to_string, $id_string;
#    print $expr->to_string, "\n";
}

