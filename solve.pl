#!/usr/bin/perl

use Puzzle24;

$|=1;

use Getopt::Std;
getopts('a', \my %opt);

my ($TARGET, @pool) = @ARGV;

my $solver = Puzzle24->new({ target => $TARGET,
                             pool => \@pool,
                             eliminate_duplicates => $opt{a} ? 0 : 1,
                           })->solver;

my %seen;
my $letter = "A";
while (my $expr = $solver->solve) {
#    printf "## %s\n", $expr->to_string;
    my $id_string = $expr->[0]->id_string;
    $seen{$id_string} //= $letter++;
    printf "%1s   %-40s %-20s %-20s\n", $seen{$id_string},
    $id_string, $expr->[0]->to_string, $expr->[0]->to_tree_string;
#    print $expr->to_string, "\n";
}

