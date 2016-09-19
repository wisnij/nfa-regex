package Regex::Expr::Empty;

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
    return 'Empty';
}


# this is a no-op; don't generate any instructions
sub compile
{
    my ($self, $prog) = @_;
    return $prog;
}


1;
