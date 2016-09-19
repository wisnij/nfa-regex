package Regex::Expr::Literal;

use strict;
use warnings;

use parent qw(Regex::Expr);


sub new
{
    my ($class, $char) = @_;
    my $self = $class->SUPER::new();
    $self->{char} = $char;
    return $self;
}


sub as_string
{
    my ($self) = @_;
    return sprintf( "Literal('%s')",
                    $self->{char} );
}


# a:
#   [1] match 'a'
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    $prog->add_match( $self->{char} );

    return $prog;
}


1;
