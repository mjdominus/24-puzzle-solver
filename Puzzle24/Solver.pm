package Puzzle24::Solver;
use Scalar::Util 'reftype';
use Moo;
use Expr ();
use Carp qw(croak);
use Solution;

# building block numbers
has init => (
  is => 'ro',
  isa => sub { reftype $_[0] eq 'ARRAY' && @{$_[0]} == 4 },
  required => 1,
);

has is_winner => (
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

has _all_solutions => (
  is => 'ro',
  init_arg => undef,
  default => sub { [] },
);
sub _append_solutions {
  my ($self, @solutions) = @_;
  push @{$self->_all_solutions}, @solutions;
}

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

has eliminate_duplicates => (
  is => 'ro',
  default => sub { 1 },
);

has seen_id_strings => (
  is => 'ro',
  default => sub { {} },
  clearer => 1,
 );

sub has_seen {
  my ($self, $str) = @_;
  my $seen = $self->seen_id_strings;
  return $seen->{$str}++;
}

sub iterator {
  my ($self) = @_;
  return sub { $self->next_solution };
}

sub all_solutions {
  my ($self) = @_;
  1 while $self->next_solution;
  return @{$self->_all_solutions};
}

sub next_solution {
  my ($self) = @_;

  until ($self->queue_empty) {
    my ($node) = $self->shift_queue;

    # is the current node a winner?
    if (expr_count($node) == 1) {
      my $expr_stuff = $node->[0];
      if ($self->is_winner->($expr_stuff)) {
        if (!($self->eliminate_duplicates && $self->has_seen(expr_id($expr_stuff)))) {
          my ($expr, $val, $intermediates) = @$expr_stuff;
          my $sol = Solution->from_expr($expr, { intermediates => $intermediates });
          $self->_append_solutions($sol);
          return $sol;
        }
      }
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
  my $new_expr = Expr::node(expr_tree($e1), $op_name, expr_tree($e2));
  return expr($new_expr, $val,
              [$val, expr_intermediates($e1), expr_intermediates($e2)]);
}

# a node has a list of unused expressions
sub node { bless [ @_ ] => "Node" }
sub exprs { my ($node) = @_; return @$node }
sub expr_count { scalar @{$_[0]} }

# an expression has: an Expr object and its value
sub base_expr {
  my ($con) = @_;
  return expr(Expr::leaf($con), Math::BigRat->new($con), []);
}
sub expr {
  my ($expr, $val, $intermediate) = @_;
  [ $expr, $val, $intermediate ];
}
sub expr_value { $_[0][1] }
sub expr_str { $_[0][0]->to_string }
sub expr_id { $_[0][0]->id_string }
sub expr_intermediates { @{$_[0][2]} }
sub expr_tree { $_[0][0] }

1;
