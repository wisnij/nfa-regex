package Regex::Scanner;

=head1 Regex::Scanner

Support class to simplify lexing the input string during parsing.

=cut

use strict;
use warnings;


=head1 METHODS

=over 4

=item B<new>( $I<STRING> )

Creates a new B<Scanner> object starting at the front of I<STRING>.

=cut

sub new
{
    my ($class, $string) = @_;
    my $obj = {
        str => $string,
        len => length($string),
        pos => 0,
    };

    return bless $obj, $class;
}


=item B<peek>( [$I<OFFSET>, $I<LENGTH>] )

Returns the substring which is I<OFFSET> characters ahead of the current
position (default 1) and I<LENGTH> characters long (default also 1).

=cut

sub peek
{
    my ($self, $offset, $length) = @_;
    $offset ||= 0;
    $offset += $self->{pos};
    return '' if $offset >= $self->{len};

    $length ||= 1;
    return substr $self->{str}, $offset, $length;
}


=item B<advance>( [$I<LENGTH>] )

Moves the current position ahead I<LENGTH> characters (default 1).

=cut

sub advance
{
    my ($self, $n) = @_;
    $n ||= 1;
    $self->{pos} += $n;
}


=item B<done>()

Returns whether the current position is before the end of the string,
i.e. whether there is any more of the input string left to consume.

=cut

sub done
{
    my ($self) = @_;
    return $self->{pos} >= $self->{len};
}


=back

=cut

1;
