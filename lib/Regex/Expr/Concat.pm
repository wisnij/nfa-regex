package Regex::Expr::Concat;

use strict;
use warnings;

use parent qw(Regex::Expr);


sub new
{
    my ($class, $lhs, $rhs) = @_;
    my $self = $class->SUPER::new();
    $self->{lhs} = $lhs;
    $self->{rhs} = $rhs;
    return $self;
}


sub as_string
{
    my ($self) = @_;
    return sprintf( "Concat(%s, %s)",
                    $self->{lhs}->as_string(),
                    $self->{rhs}->as_string() );
}


# ab:
#  [1] <code for a>
#  [2] <code for b>
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    $self->{lhs}->compile( $prog );

    # [2]
    $self->{rhs}->compile( $prog );

    return $prog;
}


1;
