package Regex::Expr::Ques;

use strict;
use warnings;

use parent qw(Regex::Expr);


sub new
{
    my ($class, $lhs, $greedy) = @_;
    my $self = $class->SUPER::new();
    $self->{lhs} = $lhs;
    $self->{greedy} = $greedy;
    return $self;
}


sub as_string
{
    my ($self) = @_;
    return sprintf( "Ques%s(%s)",
                    ($self->{greedy} ? '' : 'Ng'),
                    $self->{lhs}->as_string() );
}


# a?:
#   [1] split 2, 3
#   [2] <code for a>
#   [3] ...
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    my $split = $prog->add_split();

    # [2]
    $split->[1] = $prog->end();
    $self->{lhs}->compile( $prog );

    # [3]
    $split->[2] = $prog->end();

    # prefer shorter match if not greedy
    @$split[1, 2] = @$split[2, 1]
        if not $self->{greedy};

    return $prog;
}


1;
