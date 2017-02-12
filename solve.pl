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
    printf "%1s   %-30s %-30s\n", $seen{$id_string}, $expr->[0]->to_string, $id_string;
#    print $expr->to_string, "\n";
}

