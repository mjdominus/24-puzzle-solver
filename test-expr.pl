use Test::More;
use Expr;

my @tests = (
  # Miscellaneous expressions
  [qw(2 2 2 3 * * *)],
  [qw(4 4 * 2 / 3 *)],
  [qw(8 3 * 7 7 / *)],
  [qw(9 2 * 7 + 1 -)],
  [qw(8 3 1 - * 8 +)],
  [qw(8 1 + 8 * 3 /)],
  [qw(3 4 * 5 3 - *)],
  [qw(3 4 5 + * 3 -)],

  # Five different ways to parenthesize a+b+c+d
  [qw(4 5 6 9 + + +)],
  [qw(4 5 6 + 9 + +)],
  [qw(4 5 6 + + 9 +)],
  [qw(4 5 + 6 9 + +)],
  [qw(4 5 + 6 + 9 +)],

  # Five different ways to parenthesize a+b-c-d
  [qw(13 14 1 2 + - +)],
  [qw(13 14 1 - 2 - +)],
  [qw(13 14 1 - + 2 -)],
  [qw(13 14 + 1 2 + -)],
  [qw(13 14 + 1 - 2 -)],

  # More ways to write a+b-c-d
  [qw(13 14 + 1 2 + -)],

  # sums with zeroes
  [qw(13 0 0 11 + - +)],
  [qw(13 0 0 - 11 - +)],
  [qw(13 0 0 - + 11 -)],
  [qw(13 0 + 0 11 + -)],
  [qw(13 0 + 0 - 11 -)],
 );

subtest "all tests add to 24" => sub {
  for my $t (@tests) {
    is(from_list($t)->value, 24, "@$t");
  }
};

for my $t (@tests) {
  my $z = from_list($t)->to_ezpr;
  my $zn = $z->clone->normalize;
  note "@$t: " . $z->to_string . "    " . $zn->to_string;
#  note "@$t: " . $z->to_string;
}

done_testing();
