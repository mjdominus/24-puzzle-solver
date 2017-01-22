use Test::More;
use Expr;

sub rpn_to_id {
  my ($rpn) = @_;
  return from_list([split /\s+/, $rpn])->to_ezpr->normalize->to_string;
}

subtest "list-to-expr and expr->value" => sub {
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
   );

  for my $t (@tests) {
    is(from_list($t)->value, 24, "@$t");
  }
};

subtest "Ezpr::total_size" => sub {
  my $ezpr = Ezpr->new_node("SUM", [ Ezpr->new_con(1) ], [ Ezpr->new_con(2) ]);
  is($ezpr->total_size, 2, "regression");
};

subtest "simple normalizations" => sub {
  is(rpn_to_id("1 8 /"), "MUL [ # 8 ]");
  is(rpn_to_id("3 1 8 / /"), "MUL [ 3 8 # ]");

  is(rpn_to_id("0 8 -"), "SUM [ # 8 ]");
  is(rpn_to_id("3 0 8 - -"), "SUM [ 3 8 # ]");
};

subtest "Ezpr::compact" => sub {
  my $e1 = Ezpr->new_node("MUL",
                          [ Ezpr->new_con(3),
                            Ezpr->new_node("MUL",
                                           [ Ezpr->new_con(1) ],
                                           [ Ezpr->new_con(2) ]),
                           ], []);
  is($e1->to_string, "MUL [ 3 MUL [ 1 # 2 ] # ]", "before");
  $e1->compact;
  is($e1->to_string, "MUL [ 3 1 # 2 ]", "after");


  my $e2 = Ezpr->new_node("MUL",
                          [ Ezpr->new_con(3) ],
                          [ Ezpr->new_node("MUL",
                                           [ Ezpr->new_con(1) ],
                                           [ Ezpr->new_con(2) ]),
                           ]);
  is($e2->to_string, "MUL [ 3 # MUL [ 1 # 2 ] ]", "before 2");
  $e2->compact;
  is($e2->to_string, "MUL [ 3 2 # 1 ]", "after 2");
};

done_testing();
