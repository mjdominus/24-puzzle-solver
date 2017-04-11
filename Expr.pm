package Expr;
use base 'Exporter';
our @EXPORT = qw(leaf node to_string from_list);

sub leaf {
  my ($x) = @_;
  bless [ 'CON', $x ] => __PACKAGE__;
}

sub node {
  my ($a, $op, $b) = @_;
  bless [ $op, $a, $b ] => __PACKAGE__;
}

sub is_leaf {
  my ($self) = @_;
  $self->op eq "CON";
}

sub op { $_[0][0] }
sub con { $_[0][1] }
sub exprs { my ($op, @x) = @{$_[0]}; return @x }

# good-looking normalized expression,
# such as 6 + 2 × (2 + 7)
# or      2 × (6 + 7) - 2
sub to_string {
  my ($self) = @_;
  return $self->to_ezpr->seminormalize->to_arith_string;
}

# fully-parenthesized computer-type expression,
# such as (6 + (2 * (7 + 2)))
# or ((2 * (7 + 6)) - 2)
sub to_tree_string {
  my ($self) = @_;
  return $self->con if $self->is_leaf;
  my ($a, $b) = $self->exprs;
  sprintf "(%s %s %s)", $a->to_tree_string, $self->op, $b->to_tree_string;
}

# RPN version of expression,
# such as 7 2 + 2 * 6 +
# or 7 6 + 2 * 2 -
sub to_rpn {
  my ($self) = @_;
  return $self->con if $self->is_leaf;
  my ($a, $b) = $self->exprs;
  return join " " => $a->to_rpn, $b->to_rpn, $self->op;
}

# input: list of tokens in RPN order
# output: expression object
sub from_list {
  my (@arr) = @{$_[0]};
  my @stack;
  while (@arr) {
    my $tok = shift @arr;
    if ($tok =~ /^ [0-9]+ $/x) {
      push @stack, leaf($tok);
    } else {
      my $s1 = pop @stack;
      my $s2 = pop @stack;
      push @stack, node($s2, $tok, $s1);
    }
  }
  return pop(@stack);
}

my %f = ('+' => sub { $_[0] + $_[1] },
         '-' => sub { $_[0] - $_[1] },
         '*' => sub { $_[0] * $_[1] },
         '×' => sub { $_[0] * $_[1] },
         '/' => sub { $_[0] / $_[1] },
         '÷' => sub { $_[0] / $_[1] },
        );

sub op_to_func {
  my ($op) = @_;
  return $f{$op} // die "Unknown op '$op'\n";
}

sub value {
  my ($x) = @_;
  return $x->con if $x->is_leaf;
  my ($av, $bv) = map $_->value, $x->exprs;
  return op_to_func($x->op)->($av, $bv);
}

sub to_ezpr {
  my ($x) = @_;
  if ($x->is_leaf) {
    return Ezpr->new_con($x->con);
  }
  my $op = $x->op;
  my $covariant = Ezpr->covariant($op);
  my ($a, $b) = map $_->to_ezpr, $x->exprs;
  my $type = Ezpr->op_type($op);

  my $result = Ezpr->empty_node_of_type($type);

  if ($a->is_con || $a->type eq $type) {
    $result->merge($a->cast($type));
  } else {
    $result->install($a);
  }

  if ($b->is_con || $b->type eq $type) {
    if ($covariant) {
      $result->merge($b->cast($type));
    } else {
      $result->merge($b->cast($type)->reverse);
    }
  } else {
    if ($covariant) {
      $result->install($b);
    } else {
      $result->install(undef, $b);
    }
  }

  return $result;
}

sub id_string {
  my ($self) = @_;
  $self->to_ezpr->normalize->to_string;
}

package Ezpr;
use Scalar::Util qw(blessed);
# An Ezpr is an expression in the following form: one of
#     Con n
#     Sum [a,b,...] [m,n,...]    which represents (a+b+...)-(m+n+...)
#     Mul [a,b,...] [m,n,...]    which represents (a*b*..)/(m*n*...)

sub new_con {
  my ($base, $con) = @_;
  my $class = ref $base || $base;
  bless [ 'CON', $con ] => $class;
}
sub is_con { $_[0][0] eq "CON" }
sub con { $_[0][1] }

sub empty_node_of_type {
  my ($class, $type) = @_;
  $class->new_node($type, [], []);
}

sub new_node {
  my ($base, $type, $top, $bottom) = @_;
  my $class = ref $base || $base;
  bless [ $type, $top, $bottom ] => $class;
}


my %is_covariant = ('+' => 1, '-' => 0,
                    '*' => 1, '×' => 1,
                    '/' => 0, '÷' => 0,
                    );
sub covariant {
  my ($class, $op) = @_;
  return $is_covariant{$op} // die "Unknown op $op" ;
}

my %op_type = ('+' => 'SUM', '-' => 'SUM',
               '*' => 'MUL', '×' => 'MUL',
               '/' => 'MUL', '÷' => 'MUL',
                    );
sub op_type {
  my ($class, $op) = @_;
  return $op_type{$op} // die "Unknown op $op" ;
}

sub type { $_[0][0] }
sub top { $_[0][1] }
sub bot { $_[0][2] }

sub clone {
  my ($self) = @_;
  return $self->new_con($self->con) if $self->is_con;

  my @top = map $_->clone, @{$self->top};
  my @bot = map $_->clone, @{$self->bot};
  $self->new_node($self->type, \@top, \@bot);
}

sub reverse {
  my ($self) = @_;
  return $self->new_node($self->type, $self->bot, $self->top);
}

sub install {
  my ($self, $top, $bot) = @_;
  push @{$self->top}, $top if defined $top;
  push @{$self->bot}, $bot if defined $bot;
}

sub merge {
  my ($to, $from) = @_;
  die unless $to->type eq $from->type;
  push @{$to->top}, @{$from->top};
  push @{$to->bot}, @{$from->bot};
}

sub to_string {
  my ($self) = @_;
  if ($self->is_con) { return $self->con }
  my $type = $self->type;
  my @tops = map $_->to_string, @{$self->top};
  my @bots = map $_->to_string, @{$self->bot};
  return join " " => $type, "[", @tops, "#", @bots, "]";
}

# Convert Ezpr to normal arithmetic notation
sub to_arith_string {
  my ($self, $context) = @_;
  $context //= 'MUL';
  if ($self->is_con) { return $self->con }

  if ($self->type eq "SUM") {
    my @top = map $_->to_arith_string("SUM"), @{$self->top};
    my @bot = map $_->to_arith_string("SUM"), @{$self->bot};
    my $str = join " + " => @top;
    $str .= join(" - " => "", @bot) if @bot;
    $str = "($str)" if $context eq "PROD";
    return $str;
  } elsif ($self->type eq "MUL") {
    my @top = map $_->to_arith_string("PROD"), @{$self->top};
    my @bot = map $_->to_arith_string("PROD"), @{$self->bot};
    if (@top == 1 && @bot == 1) {
      $str = "$top[0]/$bot[0]";
    } else {
      my ($numerator, $denominator) = ("", "");
      if (@top > 1) {
        $numerator = join(" × " => @top);
      } else {
        $numerator = $top[0];
      }

      if (@bot > 1) {
        $denominator = join(" × " => @bot);
      } else {
        $denominator = $bot[0];
      }

      if (@bot) {
        $str = join " ÷ " => $numerator, $denominator;
      } else {
        $str = $numerator;
      }
    }
    return $str;
  } else { die "wut" }
}


sub cast {
  my ($self, $type) = @_;
  return $self if $self->type eq $type;
  die sprintf "can't cast %s to type %s\n", $self->type, $type
    unless $self->is_con;

  return $self->new_node($type, [ $self ], []);
}

my %identity = (SUM => 0, MUL => 1);
sub normalize {
  my ($self, $opt) = @_;

  return $self if $self->is_con;

  if ($self->type eq "MUL" && $self->contains_zero) {
    $self->become_zero;
    return $self;
  # } elsif ($self->type eq "SUM" && $self->is_simple_zero) {
  #   $self->become_zero;
  #   return;
  }

  # Recursively normalize subexpressions
  for my $sub (@{$self->top}, @{$self->bot}) {
    $sub->normalize;
  }

  $self->compact;

  # eliminate common items from both top and bottom
  # This also eliminates common zeroes, which is okay, because
  # they would be eliminated anyway from sums, and we already returned early
  # if the numeraotr of a mul contains any
  {
    my %top;
    for my $x (grep $_->is_con, @{$self->top}) { push @{$top{$x->con}}, $x }
    for my $x (grep $_->is_con, @{$self->bot}) {
      my $val = $x->con;
      if (@{$top{$val}}) {
        $top{$val}[0][0] = "KILL";
        shift @{$top{$val}};
        $x->[0] = "KILL";
      }
    }
    @{$self->top} = grep ! ($_->[0] eq "KILL"), @{$self->top};
    @{$self->bot} = grep ! ($_->[0] eq "KILL"), @{$self->bot};
  }

  # eliminate identity elements
  my $id = $identity{$self->type};
  @{$self->top} = grep ! ($_->value == $id), @{$self->top};
  @{$self->bot} = grep ! ($_->value == $id), @{$self->bot};

  # If there's hardly anything left, turn self into a constant
  { my $total_size = $self->total_size;
    if ($total_size == 0) {
      $self->become_constant($self->value);
      return $self;
    } elsif ($total_size == 1) {
      # EXCEPTION: MUL [ # 3 ] and SUB [ # 3 ] should not turn into 3!!
      # (should SUB [ # 3 ] turn into CON -3?)
      unless (@{$self->top} == 0) {
        my ($item) = (@{$self->top}, @{$self->bot});
        @{$self} = @$item;
        return $self;
      }
    }
  }

  # sort by value
  @{$self->top} = sort by_expr_value @{$self->top};
  @{$self->bot} = sort by_expr_value @{$self->bot};

  return $self;
}

# Omits a lot of optimizations done by normalization
# The idea here is to leave the expression in an equivalent form
# **with the same constants**
# For example instead of  (4 - (2 + (3 - 5))) we'd like to write
#   4 + 5 - 2 - 3
sub seminormalize {
  my ($self, $opt) = @_;

  return if $self->is_con;

  # Recursively normalize subexpressions
  for my $sub (@{$self->top}, @{$self->bot}) {
    $sub->seminormalize;
  }

  $self->compact;

  # sort by value
  @{$self->top} = sort by_expr_value @{$self->top};
  @{$self->bot} = sort by_expr_value @{$self->bot};

  return $self;
}

sub by_expr_value {
  # constants come first
  if ($b->is_con) {
    if ($a->is_con) {
      return $a->con <=> $b->con;
    } else {
      return 1;
    }
  } elsif ($a->is_con) {
    return -1;
  }

  # neither is a constant
  return $a->value <=> $b->value
         || $a->to_string cmp $b->to_string;
}

# a product contains a factor of 0 in its numerator
sub contains_zero {
  my ($self) = @_;
  for my $sub (@{$self->top}) { return 1 if $sub->is_con && $sub->con == 0 }
  return;
}

# # the postiive and negative parts of a sum are equal
# sub is_simple_zero {
#   my ($self) = @_;
#   my $sum = 0;
#   for my $x (@{$self->top}) { return unless $x->is_con;
#                               $sum += $x->con }
#   for my $x (@{$self->bot}) { return unless $x->is_con;
#                               $sum -= $x->con }
#   return $sum == 0;
# }

# mutate object to turn it into a constant
sub become_constant {
  my ($self, $con) = @_;
  @$self = @{$self->new_con($con)};
}

sub become_zero {
  my ($self) = @_;
  $self->become_constant(0);
}

# If this expression has any subexpressions of the same type,
# lift the subexpressions up one node
sub compact {
  my ($self) = @_;
  my $type = $self->type;
  my @new_top;
  my @new_bot;

  for my $x (@{$self->top}) {
    if ($x->type eq $type) {    # lift
      push @new_top, @{$x->top};
      push @new_bot, @{$x->bot};
    } else {
      push @new_top, $x;
    }
  }
  for my $x (@{$self->bot}) {
    if ($x->type eq $type) {    # lift
      push @new_bot, @{$x->top};
      push @new_top, @{$x->bot};
    } else {
      push @new_bot, $x;
    }
  }
  @{$self->top} = @new_top;
  @{$self->bot} = @new_bot;
}

sub sum {
  my $sum = 0;
  $sum += $_ for @_;
  return $sum;
}

sub prod {
  my $prod = 1;
  $prod *= $_ for @_;
  return $prod;
}

sub value {
  my ($self) = @_;
  return $self->con if $self->is_con;
  my @top = map $_->value, @{$self->top};
  my @bot = map $_->value, @{$self->bot};
  if ($self->type eq "SUM") {
    return sum(@top) - sum(@bot);
  } elsif ($self->type eq "MUL") {
    return prod(@top) / prod(@bot);
  } else {
    die "What? " . $self->type;
  }
}

sub total_size {
  my ($self) = @_;
  my @x = (@{$self->top}, @{$self->bot});
  return 0 + @x;
}

# all subexpressions are constants
sub is_simple {
  my ($self) = @_;
  return 1 if $self->is_con;
  for my $x (@{$self->top}, @{$self->bot}) { return unless $x->is_con }
  return 1;
}

1;
