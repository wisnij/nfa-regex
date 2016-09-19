package Regex::Prog::Op;

use strict;
use warnings;


sub new
{
    my ($class, $code, @args) = @_;
    my $obj = [ $code, @args ];
    return bless $obj, $class;
}


sub as_string
{
    my ($self) = @_;
    my $str = $self->[0];
    $str .= join( ',', map { " $self->[$_]" } 1 .. $#$self );
    return $str;
}


sub code
{
    my ($self) = @_;
    return $self->[0];
}


sub args
{
    my ($self) = @_;
    return @$self[1 .. $#$self];
}


1;
