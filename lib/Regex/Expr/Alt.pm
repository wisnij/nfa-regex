package Regex::Expr::Alt;

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
    return sprintf( "Alt(%s, %s)",
                    $self->{lhs}->as_string(),
                    $self->{rhs}->as_string() );
}


# a|b:
#   [1] split 2, 4
#   [2] <code for a>
#   [3] goto 5
#   [4] <code for b>
#   [5] ...
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    my $split = $prog->add_split();

    # [2]
    $split->[1] = $prog->end();
    $self->{lhs}->compile( $prog );

    # [3]
    my $goto = $prog->add_goto();

    # [4]
    $split->[2] = $prog->end();
    $self->{rhs}->compile( $prog );

    # [5]
    $goto->[1] = $prog->end();

    return $prog;
}


1;
