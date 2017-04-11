package Puzzle24;

use Math::BigRat;
use Moo;
use Scalar::Util 'reftype';
use Carp qw(croak);
use Puzzle24::Solver;

has target => (
  is => 'ro',
  required => 0,
 );

has is_winner => (
  is => 'ro',
  lazy => 1,
  builder => 1,
 );

# It would be better if there was a construct-time error message thrown
sub _build_is_winner {
  my ($self) = @_;
  my $target = $self->target;
  croak "No target or winner function specified" unless defined $target;
  sub { Puzzle24::Solver::expr_value($_[0]) == $target };
}

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

has eliminate_duplicates => (
  is => 'ro',
  default => sub { 1 },
);

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
                            is_winner => $self->is_winner,
                            eliminate_duplicates => $self->eliminate_duplicates,
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

1;
