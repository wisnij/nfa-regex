package Regex::Expr::Any;

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
    return 'Any';
}


# a:
#   [1] any
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    $prog->add_any();

    return $prog;
}


1;
