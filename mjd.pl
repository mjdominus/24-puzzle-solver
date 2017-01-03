#!/usr/bin/perl

use Math::BigRat;

$|=1;

# There are no puzzles that require the use of negative intermediate results
my $negative_allowed = 1;

# However there are 7 puzzles that require the use of fractional intermediate results
my $fraction_allowed = 1;

my ($TARGET, $size) = @ARGV;
die unless defined $TARGET;
$size //= 4;

my %score;
while (<DATA>) {
  s/#.*//;
  s/^\s+//;   s/\s+$//;
  next unless /\S/;
  my ($im, $score) = split;
  $score{$im} = $score;
}

my $ops = [
  [ '+' => sub { $_[0] + $_[1] } ],
  [ '-' => sub { $_[0] - $_[1] } ],
  [ '-' => sub { $_[1] - $_[0] }, 'r'],
  [ '*' => sub { $_[0] * $_[1] } ],
  [ '/' => sub { return $_[1] == 0 ? () : $_[0] / $_[1] } ],
  [ '/' => sub { return $_[0] == 0 ? () : $_[1] / $_[0] }, 'r' ],
 ];
sub reversed { $_[0][2] =~ /r/ }

my @o = (0) x $size;
# test bump()
#while (1) { print "@o\n";
#            exit unless bump(\@o); }
while (1) {
  my $sols = solve($TARGET, \@o);
  if ($sols) {
    my $puzzle_score;
    # the weirdness of a puzzle is the _highest_ score among its solutions
    for my $sol (@$sols) {
#      for my $im (expr_intermediates($sol)) {
#        $score{$im}++;
#      }
      # the weirdness of a solution is the _lowest_ score among its intermediate results
#      my $solution_score = expr_weirdness($sol);
#      $puzzle_score = $solution_score if $solution_score > $puzzle_score;
#      print STDERR "$COUNT (@o)\n" if ++$COUNT % 100 == 0;
    }
#    printf "(@o) %d\n", $puzzle_score;
  }
  #  printf "(@o) %d\n", 0 + @$sols if defined $sols;
  print "(@o) ", expr_str($sols->[0]), "\n" if defined $sols;
  print STDERR "$COUNT (@o)\n" if ++$COUNT % 100 == 0;
  last unless bump(\@o);
}

#for my $i (sort {$a <=> $b} keys %score) {
#  printf "%s %5d\n", $i, $score{$i} ;
#}

exit;

# score of the most unusual intermediate result
sub expr_weirdness {
  my ($expr) = @_;
  my ($im) = sort {$score{$a} <=> $score{$b} } grep $_ != 24, expr_intermediates($expr);
  return $score{$im};
}

sub bump {
  my ($o) = @_;
  my $i = $#$o;
  $o->[$i--] = 0 while $o->[$i] == 9;
  return if $i < 0;
  $o->[$i++]++;
  $o->[$i++] = $o->[$i-1] while $i < @o;
  return 1;
}

  # a node has a list of unused expressions
sub node { bless [ @_ ] => "Node" }
sub exprs { my ($node) = @_; return @$node }
sub expr_count { scalar @{$_[0]} }

# an expression has: the stringization and its value
sub base_expr {
  my ($con) = @_;
  return expr($con, Math::BigRat->new($con), []);
}
sub expr {
  my ($string, $val, $intermediate) = @_;
  [ $string, $val, $intermediate ];
}
sub expr_value { $_[0][1] }
sub expr_str { $_[0][0] }
sub expr_intermediates { @{$_[0][2]} }

sub solve {
  my ($TARGET, $pool, $opt) = @_;
#  warn "solve(@$pool) => $TARGET\n";
  $opt //= {};
  my @found;

  my @queue = node(map base_expr($_), @$pool);

  while (@queue) {
    my ($node) = shift @queue;

    # is the current node a winner?
    if (expr_count($node) == 1) {
      my $expr = $node->[0];
      if (expr_value($expr) == $TARGET) {
        push @found, $expr;
        return \@found if exists $opt->{max} && @found >= $opt->{max};
      }
    }

    # find the nodes that follow this one in the search
    my @exprs = exprs($node);
    for my $i (0 .. $#exprs) {
      my $expr_1 = $exprs[$i];
      for my $j ($i+1 .. $#exprs) {
        my $expr_2 = $exprs[$j];
        for my $op (@$ops) {
          if (defined (my $new_expr = combine($op, $expr_1, $expr_2))) {
            my @new_pool = exprs($node);
            splice @new_pool, $_, 1
              for sort { $b <=> $a } $i, $j;
            unshift @queue, node(@new_pool, $new_expr);
          }
        }
      }
    }
  }

  return @found ? \@found : () ;
}

sub combine {
  my ($op, $e1, $e2) = @_;
  my ($op_name, $calc) = @$op;
  my $val = $calc->(expr_value($e1), expr_value($e2));
  return unless defined $val;
  return if ! $negative_allowed && $val < 0;
  return if ! $fraction_allowed && ! $val->is_int;
  ($e1, $e2) = ($e2, $e1) if reversed($op);
  my $new_expr = "(" . expr_str($e1) . " $op_name " . expr_str($e2) . ")";
  return expr($new_expr, $val,
              [$val, expr_intermediates($e1), expr_intermediates($e2)]);
}

__END__
# For each number on the left, how often
# the number appears as an intermediate result
# in a solution
-24    38
-23     9
-22     8
-21    32
-20    41
-19    12
-18    60
-17    16
-16    72
-15    64
-9    22
-8   105
-7    44
-6   168
-5    71
-4   180
-3   207
-2   135
-1   131
0   832
1/6   195
1/24    18
1/12    37
1/5    15
1/7     4
1/2   171
1/4   298
1/9     7
1  1235
1/8   176
1/3   385
2/3   124
2/9     2
2/5     2
2   728
2/7     2
3/2   122
3/4    59
3  1797
3/7    14
3/5    10
3/8   117
4/3    58
4/5    12
4/9     9
4  1773
4/7    12
5/6    13
5/24    12
5/2     2
5/4    13
5/8    19
5   209
5/3    16
6/7     8
6/5    12
6  1768
7/3    16
7/2     2
7   151
7/4    13
7/8    13
7/6    13
7/24    12
8/9     8
8  1677
8/3   152
8/7     8
8/5    14
9/5     2
9   323
9/2     2
9/4    14
9/8    13
10   208
11   143
12  1151
13    95
14   155
15   407
16   683
17   156
18   524
19    66
20   262
21   243
22    47
23    29
24 12529
24/7    28
24/5    36
25   215
26    25
27   225
28   201
29    19
30   192
31    15
32   211
33    23
35    24
36   162
40    45
42    27
45     5
48   156
49     3
54    23
56    21
63     4
64    36
72   127
81     5
96    27
120    15
144    25
168    12
192    15
216    15
