
package Solution;
use Moo;
use Carp qw(confess croak);

# A solution is a pair of Expr and corresponding Ezpr, plus possibly
# some annotations

sub new {
  my ($class, $expr, $ezpr, $notes) = @_;
  croak "Missing expr" unless defined $expr;
  croak "Missing ezpr" unless defined $ezpr;
  $notes ||= {};
  bless [ $expr, $ezpr, $notes ] => $class;
}

sub expr { $_[0][0] }
sub ezpr { $_[0][1] }
sub notes { $_[0][2] }
sub note { $_[0][2]{$_[1]} }             # k
sub annotate { $_[0][2]{$_[1]} = $_[2] } # k v

sub from_expr {
  $DB::single = 1;
  my ($class, $expr, $notes) = @_;
  $notes //= {};
  $class->new($expr, $expr->to_ezpr, $notes);
}

sub id_string { $_[0][0]->id_string }
sub to_string { $_[0][0]->to_string }
sub to_tree_string { $_[0][0]->to_tree_string }

1;
