package Regex::Expr::Plus;

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
    return sprintf( "Plus%s(%s)",
                    ($self->{greedy} ? '' : 'Ng'),
                    $self->{lhs}->as_string() );
}


# a+:
#   [1] <code for a>
#   [2] split 1, 3
#   [3] ...
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    my $addr1 = $prog->end();
    $self->{lhs}->compile( $prog );

    # [2]
    my $split = $prog->add_split();

    # [3]
    $split->[1] = $addr1;
    $split->[2] = $prog->end();

    # prefer shorter match if not greedy
    @$split[1, 2] = @$split[2, 1]
        if not $self->{greedy};

    return $prog;
}


1;
