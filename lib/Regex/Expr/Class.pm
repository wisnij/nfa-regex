package Regex::Expr::Class;

use strict;
use warnings;

use parent qw(Regex::Expr);


sub new
{
    my ($class, $negated, @ranges) = @_;
    my $self = $class->SUPER::new();
    $self->{negated} = $negated;
    $self->{ranges} = \@ranges;
    return $self;
}


sub range_string
{
    my ($self) = @_;
    if( not defined $self->{range_string} )
    {
        my $str = '';
        for my $range ( @{ $self->{ranges} } )
        {
            if( ref $range eq 'ARRAY' )
            {
                # an actual range; append the lower and upper bounds as a pair
                my ($l, $u) = @$range;
                $str .= $l . $u;
            }
            elsif( length $range == 1 )
            {
                # a single character, so create a "pair" with the same char at
                # both ends
                $str .= $range x 2;
            }
        }

        $self->{range_string} = $str;
    }

    return $self->{range_string};
}


sub as_string
{
    my ($self) = @_;
    return sprintf( 'Class%s(%s)',
                    ($self->{negated} ? 'Not' : ''),
                    $self->range_string() );
}


# [abc]:
#   [1] match 'a', 'b', 'c'
sub compile
{
    my ($self, $prog) = @_;

    # [1]
    $prog->add_range( $self->{negated}, $self->range_string() );

    return $prog;
}


1;
