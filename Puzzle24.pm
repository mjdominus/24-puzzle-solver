package Puzzle24;

use Math::BigRat;
use Moo;
use Scalar::Util 'reftype';

has target => (
  is => 'ro',
  required => 1,
);

has size => (
  is => 'ro',
  default => sub { 4 },
);

has pool => (
  is => 'ro',
  isa => sub { reftype($_[0]) eq 'ARRAY' && @{$_[0]} == 4 },
  default => sub { [ (0) x $_[0]->size ] },
  lazy => 1,
 );

sub pool_string {
  my ($self, $sep, $pre, $post) = @_;
  $sep //= " ";
  $pre //= "";
  $post //= "";
  $pre . join($sep => @{$self->pool}) . $post;
}


has solver => (
  is => 'rwp',
  lazy => 1,
  builder => 1,
  clearer => 1,
);

sub _build_solver {
  my ($self) = @_;
  return
    Puzzle24::Solver->new({ init   => $self->pool,
                            target => $self->target,
                          });
}


sub all_solutions {
  my ($self) = @_;
  my $solver = $self->solver;
  my @sol;
  while (my $solution = $solver->solve) {
    push @sol, $solution;
  }
  return \@sol;
}

sub one_solution {
  $_[0]->solver->solve;
}

sub bump {
  my ($self) = @_;
  $self->clear_solver;
  my ($o) = $self->pool;
  my $i = $#$o;
  $o->[$i--] = 0 while $o->[$i] == 9;
  return if $i < 0;
  $o->[$i++]++;
  $o->[$i++] = $o->[$i-1] while $i < @$o;
  return 1;
}

package Puzzle24::Solver;
use Scalar::Util 'reftype';
use Moo;

# building block numbers
has init => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'ARRAY' && @{$_[0]} == 4 },
  required => 1,
);

has target => (
  is => 'ro',
  required => 1,
);

has ops => (
  is => 'ro',
  builder => 1,
 );

sub op_list { @{$_[0]->ops} }

sub _build_ops {
  [
    [ '+' => sub { $_[0] + $_[1] } ],
    [ '-' => sub { $_[0] - $_[1] } ],
    [ '-' => sub { $_[1] - $_[0] }, 'r'],
    [ '*' => sub { $_[0] * $_[1] } ],
    [ '/' => sub { return $_[1] == 0 ? () : $_[0] / $_[1] } ],
    [ '/' => sub { return $_[0] == 0 ? () : $_[1] / $_[0] }, 'r' ],
   ];
}

has debug => (
  is => 'rw',
  default => sub { 0 },
);

# not a method
sub reversed { $_[0][2] && $_[0][2] =~ /r/ }

has queue => (
  is => 'ro',
  lazy => 1,
  init_arg => undef,
  builder => 1,
 );

sub _build_queue {
  my ($self) = @_;
  [ node(map base_expr($_), @{$self->init}) ]
}

sub queue_empty {
  my ($self) = @_;
  @{$self->queue} == 0;
}

sub shift_queue {
  my ($self) = @_;
  shift @{$self->queue};
}

sub push_queue {
  my ($self, @items) = @_;
  unshift @{$self->queue}, @items;
}

sub solve {
  my ($self) = @_;

  until ($self->queue_empty) {
    my ($node) = $self->shift_queue;

    # is the current node a winner?
    if (expr_count($node) == 1) {
      my $expr = $node->[0];
      return $expr if expr_value($expr) == $self->target;
    }

    # find the nodes that follow this one in the search
    my @exprs = exprs($node);
    for my $i (0 .. $#exprs) {
      my $expr_1 = $exprs[$i];
      for my $j ($i+1 .. $#exprs) {
        my $expr_2 = $exprs[$j];
        for my $op ($self->op_list) {
          if (defined (my $new_expr = $self->combine($op, $expr_1, $expr_2))) {
            my @new_pool = exprs($node);
            splice @new_pool, $_, 1
              for sort { $b <=> $a } $i, $j;
            $self->push_queue(node(@new_pool, $new_expr));
          }
        }
      }
    }
  }

  return;
}

has negative_allowed => (
  is => 'rw',
  default => 0,
);

has fraction_allowed => (
  is => 'rw',
  default => 1,
);

sub combine {
  my ($self, $op, $e1, $e2) = @_;
  my ($op_name, $calc) = @$op;
  my $val = $calc->(expr_value($e1), expr_value($e2));
  return unless defined $val;
  return if ! $self->negative_allowed && $val < 0;
  return if ! $self->fraction_allowed && ! $val->is_int;
  ($e1, $e2) = ($e2, $e1) if reversed($op);
  my $new_expr = "(" . expr_str($e1) . " $op_name " . expr_str($e2) . ")";
  return expr($new_expr, $val,
              [$val, expr_intermediates($e1), expr_intermediates($e2)]);
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

1;
