#!/usr/bin/perl

use Puzzle24;

$|=1;

use Getopt::Std;
getopts('a', \my %opt);

my ($TARGET, @pool) = @ARGV;

my $puzzle = Puzzle24->new({ target => $TARGET,
                             pool => \@pool,
                           });
my $solver = $puzzle->solver({eliminate_duplicates => $opt{a} ? 0 : 1});
my $solutions = $solver->iterator;

my %seen;
my $letter = "A";
while (my $solution = $solutions->()) {
#    printf "## %s\n", $expr->to_string;
    my $id_string = $solution->id_string;
    $seen{$id_string} //= $letter++;
    printf "%1s   %-40s %-20s %-20s\n", $seen{$id_string},
    $id_string, $solution->to_string, $solution->to_tree_string;
#    print $expr->to_string, "\n";
}

