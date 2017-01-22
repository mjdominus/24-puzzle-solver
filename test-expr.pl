use Test::More;
use Expr;

sub rpn_to_id {
  my ($rpn) = @_;
  return from_list([split /\s+/, $rpn])->to_ezpr->normalize->to_string;
}

subtest "normalizations of various complete expressions" => sub {

  # given a bunch of RPN expressions and an expected normal ID string,
  # make sure each expression normalizes to the expected string
  my $check = sub {
    my ($rpns, $idstring, $msg) = @_;
    my $i = 1;
    subtest "checking normalizations to '$idstring'" => sub {
      for my $rpn (@$rpns) {
        my $_msg = $msg ? "$msg ($rpn)" : "($rpn)";
        is(rpn_to_id($rpn), $idstring, $_msg);
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

  # Bug revealed by first run of exhaustive solution generator
  subtest "0 1 3 8 : one solution but we thought it was three" => sub {
    $check->([
      "3 8 * 1 / 0 -",
      "3 1 8 / 0 - /",
      "8 1 3 / 0 - /",
     ], "MUL [ 3 8 # ]", "zero and one handling errors");
    $check->([
      "4 6 * 1 / 0 -",
      "4 1 6 / 0 - /",
      "6 1 4 / 0 - /",
     ], "MUL [ 4 6 # ]", "this is probably the same thing");
    $check->([
      "2 2 6 * * 0 -",
      "2 2 6 * 0 - *",
      "6 2 2 * 0 - *",
     ], "MUL [ 2 2 6 # ]", "probably simpler version of the same thing");
  };

  # I'm not sure if this is a bug; nor is Lily
  subtest "2 3 4 6 : is X / Y the same as X * Y when Y is a compound expression with value 1?" => sub {
    local $TODO = "We aren't sure if these are bugs";
    $check->([
      "4 6 * 3 2 - *",
      "4 6 * 3 2 - /",
     ], "MUL [ 4 6 # ]");

    # Similar case with + or - zero instead of * or / 1.
    $check->([
      "4 6 * 3 3 - -",
      "4 6 * 3 3 - +",
     ], "MUL [ 4 6 # ]");
  };
};

subtest "various things that should not be conflated" => sub {
  my $check = sub {
    my ($rpns, $msg) = @_;
    $msg //= "comparison ";
    my $n = @$rpns;
    my $count = 0;
    subtest "checking distinctness of $n expressions" => sub {
      for my $i (0 .. $#$rpns-1) {
        my $id_i = from_list([split /\s+/, $rpns->[$i]])->to_ezpr->normalize->to_string;
        note "$rpns->[$i]:   $id_i";
        for my $j ($i+1 .. $#$rpns) {
          my $id_j = from_list([split /\s+/, $rpns->[$j]])->to_ezpr->normalize->to_string;
          note "  $rpns->[$j]: $id_j";
          isnt($id_i, $id_j, $msg. ++$count);
        }
      }
    };
  };

  $check->(["2 3 4 * * 1 /", "2 4 + 1 3 + *", "4 1 2 3 + + *"]);
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
