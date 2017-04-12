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

sub bump {
  my ($self) = @_;
  my ($o) = $self->pool;
  my $i = $#$o;
  $o->[$i--] = 0 while $o->[$i] == 9;
  return if $i < 0;
  $o->[$i++]++;
  $o->[$i++] = $o->[$i-1] while $i < @$o;
  return 1;
}

sub solver {
  my ($self, $opts) = @_;
  my $target = $self->target;
  $opts //= {};
  Puzzle24::Solver->new({ init   => $self->pool,
                          is_winner =>
                            sub { Puzzle24::Solver::expr_value($_[0]) == $target },
                          %$opts,
                        });
}

1;
