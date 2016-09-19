package Regex::Expr::Group;

use strict;
use warnings;

use parent qw(Regex::Expr);


sub new
{
    my ($class, $content, $n) = @_;
    my $self = $class->SUPER::new();
    $self->{content} = $content;
    $self->{n} = $n;
    return $self;
}


sub as_string
{
    my ($self) = @_;
    return sprintf 'Group(%d, %s)', $self->{n}, $self->{content}->as_string();
}


# (a):
#   [1] save 0
#   [2] <code for a>
#   [3] save 1
sub compile
{
    my ($self, $prog) = @_;
    my $n = $self->{n};

    # [1]
    $prog->add_save( 2*$n );

    # [2]
    $self->{content}->compile( $prog );

    # [3]
    $prog->add_save( 2*$n + 1 );

    return $prog;
}


1;
