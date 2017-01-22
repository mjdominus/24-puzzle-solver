use Test::More;
use Expr;

subtest "various normalizations" => sub {

  my $check = sub {
    my ($rpns, $idstring, $msg) = @_;
    my $i = 1;
    subtest "checking normalizations to '$idstring'" => sub {
      for my $rpn (@$rpns) {
        my $_msg = $msg ? "$msg ($rpn)" : "($rpn)";
        is(from_list([split /\s+/, $rpn])->to_ezpr->normalize->to_string, $idstring, $_msg);
        $i++;
      }
    };
  };

  subtest "2 2 2 3 : two solutions" => sub {
    $check->(["2 2 * 2 3 * *",
              "2 2 2 3 * * *",
              "2 3 * 2 2 * *",
              "2 3 2 2 * * *",
              "2 2 * 2 * 3 *",],
             "MUL [ 2 2 2 3 # ]");

    $check->(["2 2 + 2 3 * *",
              "2 3 * 2 2 + *",
              "2 3 2 2 + * *",
              "3 2 2 2 + * *",
             ], "MUL [ 2 3 SUM [ 2 2 # ] # ]");
  };


  subtest "4 4 2 3 : three solutions" => sub {
    $check->(["3 2 / 4 4 * *",
              "3 2 4 / 4 / /",
              "3 2 4 4 * / /",
              "3 4 2 4 / / *",
              "3 4 4 * * 2 /",

              "3 4 4 * 2 / *",
              "3 4 4 2 / * *",
              "4 2 4 / 3 / /",
              "4 2 / 4 3 * *",
              "4 2 4 / 3 / /",

              "4 2 4 3 * / /",
              "4 3 * 2 4 / /",
              "4 3 2 4 / / *",
              "4 3 * 4 2 / *",
              "4 3 4 2 / * *",

              "4 4 * 2 3 / /",
              "4 4 2 3 / / *",
              "4 4 3 * * 2 /",
              "4 4 * 3 2 / *",
              "4 4 3 * 2 / *",

              "4 4 3 2 / * *",
             ], "MUL [ 3 4 4 # 2 ]");

    $check->(["4 4 2 3 + * +"], "SUM [ 4 MUL [ 4 SUM [ 2 3 # ] # ] # ]");

    $check->(["3 4 4 2 - * *",
              "4 2 - 4 3 * *",
              "4 3 * 4 2 - *",
              "4 3 4 2 - * *",
             ], "MUL [ 3 4 SUM [ 4 # 2 ] # ]");
  };

  # These are interesting because they test the way the 7/7=1 and the 7-7=0 parts cancel
  subtest "8 3 7 7 : one solution; various cancellations" => sub {
    $check->([
      "3 7 * 7 8 / /", "3 7 7 / 8 / /", "3 7 7 8 / / *", "3 7 / 8 7 * *", "3 7 * 8 7 / *",
      "3 7 8 / 7 / /", "3 7 8 7 - + *", "3 7 8 7 / * *", "3 7 8 7 * / /", "3 8 7 * * 7 /",
      "3 8 7 * 7 / *", "3 8 7 + 7 - *", "3 8 7 7 - - *", "3 8 7 7 - + *", "3 8 7 7 / / *",
      "3 8 7 7 / * *", "7 3 7 8 / / *", "7 3 8 7 / * *", "7 7 3 / 8 / /", "7 7 - 8 3 * +",
      "7 7 / 8 3 * *", "7 7 8 / 3 / /", "7 7 8 3 * / /", "7 8 3 * * 7 /", "7 8 3 * + 7 -",
      "7 8 3 * 7 - +", "7 8 3 * 7 / *", "7 8 3 7 / * *", "7 8 7 3 / / *", "8 3 * 7 7 - -",
      "8 3 * 7 7 - +", "8 3 * 7 7 / /", "8 3 * 7 7 / *", "8 3 7 * * 7 /", "8 3 7 * 7 / *",
      "8 3 7 + 7 - *", "8 3 7 7 - - *", "8 3 7 7 - + *", "8 3 7 7 / / *", "8 3 7 7 / * *",
      "8 7 / 3 7 * *", "8 7 * 3 7 / *", "8 7 3 / 7 / /", "8 7 3 7 / * *", "8 7 3 7 * / /",
      "8 7 * 7 3 / /", "8 7 7 / 3 / /", "8 7 7 3 - - *", "8 7 7 3 / / *",
     ], "MUL [ 3 8 # ]");
  };

  # I'm not sure these are actually interesting, but what the heck
  subtest "9 2 7 1 : two solutions" => sub {
    $check->([
      "7 1 - 9 2 * +",
      "7 9 2 * + 1 -",
      "7 9 2 * 1 - +",
      "9 2 * 7 1 - +",
     ], "SUM [ 7 MUL [ 2 9 # ] # 1 ]");

    $check->([
      "1 9 2 7 * + +",
      "2 7 * 9 1 + +",
      "9 1 + 2 7 * +",
      "9 1 2 7 * + +",
     ], "SUM [ 1 9 MUL [ 2 7 # ] # ]");
  };
};

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

subtest "zero handling in sums" => sub {
  my @tests = (
    # sums with zeroes
    [qw(13 0 0 11 + - +)],
    [qw(13 0 0 - 11 - +)],
    [qw(13 0 0 - + 11 -)],
    [qw(13 0 + 0 11 + -)],
    [qw(13 0 + 0 - 11 -)],
   );

  for my $t (@tests) {
    my $z = from_list($t)->to_ezpr;
    my $zn = $z->clone->normalize;
    is($zn->to_string, "SUM [ 13 # 11 ]", "@$t");
    #    note "@$t: " . $z->to_string . "    " . $zn->to_string;
    #  note "@$t: " . $z->to_string;
  }
};

subtest "Ezpr::total_size" => sub {
  my $ezpr = Ezpr->new_node("SUM", [ Ezpr->new_con(1) ], [ Ezpr->new_con(2) ]);
  is($ezpr->total_size, 2, "regression");
};


done_testing();
