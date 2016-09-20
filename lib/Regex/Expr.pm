package Regex::Expr;

=head1 NAME

Regex::Expr - Abstract base class for regexp expressions

=cut

use strict;
use warnings;

# bring in all the Expr subclasses here
use Regex::Expr::Alt;
use Regex::Expr::Any;
use Regex::Expr::Concat;
use Regex::Expr::Class;
use Regex::Expr::Empty;
use Regex::Expr::Group;
use Regex::Expr::Literal;
use Regex::Expr::Plus;
use Regex::Expr::Ques;
use Regex::Expr::Star;


=head1 METHODS

=over 4

=item B<new>()

Create a new expression.  This should never be called directly, only by
subclasses' constructors.

=cut

sub new
{
    my ($class) = @_;
    die "direct instantiation of $class not allowed"
        if $class eq __PACKAGE__;

    my $obj = {};
    return bless $obj, $class;
}


=item B<as_string>()

Convert the expression into a human-readable string representation, for
debugging.  (This is a stub method which the concrete subclasses must implement
on their own.)

=cut

sub as_string
{
    my ($self) = @_;
    my $class = ref $self;
    die "${class}::as_string not implemented!";
}



=item B<compile>()

Compile the expression into bytecode.  (This is a stub method which the
concrete subclasses must implement on their own.)

=cut

sub compile
{
    my ($self) = @_;
    my $class = ref $self;
    die "${class}::compile not implemented!";
}


=back

=cut

1;
