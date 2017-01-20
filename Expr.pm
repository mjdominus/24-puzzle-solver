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

sub to_string {
  my ($self) = @_;
  if ($self->is_leaf) {
    return $self->con;
  } else {
    my ($a, $b) = $self->exprs;
    return join " " => "(", $a->to_string, $self->op, $b->to_string, ")";
  }
}

# RPN
sub from_list {
  my (@arr) = @{$_[0]};
  my @stack;
  while (@arr) {
    my $tok = shift @arr;
    if ($tok =~ /^ [1-9] [0-9]* $/x) {
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
    $result->install(undef, $b);
  }

  return $result;
}

package Ezpr;
use Scalar::Util qw(blessed);
# An Ezpr is an expression in the following form: one of
#     Con n
#     Sum [a,b,...] [m,n,...]    which represents (a+b+...)-(m+n+...)
#     Mul [a,b,...] [m,n,...]    which represents (a*b*..)/(m*n*...)

sub new_con {
  my ($class, $con) = @_;
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
  my @tops = map blessed($_) ? $_->to_string : $_, @{$self->top};
  my @bots = map blessed($_) ? $_->to_string : $_, @{$self->bot};
  return join " " => $type, "[", @tops, "#", @bots, "]";
}

sub cast {
  my ($self, $type) = @_;
  return $self if $self->type eq $type;
  die sprintf "can't cast %s to type %s\n", $self->type, $type
    unless $self->is_con;

  return $self->new_node($type, [ $self->con ], []);
}

1;
