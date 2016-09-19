package Regex::Prog;

=head1 NAME

Regex::Prog - a compiled representation of a regular expression

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use Regex::Prog::Op;


=head1 METHODS

=over 4

=item B<new>()

Create a new, empty program.

=cut

sub new
{
    my ($class) = @_;
    my $obj = {
        ops => [],
    };

    return bless $obj, $class;
}


=item B<as_string>()

Convert the program to a human-readable string representation.

=cut

sub as_string
{
    my ($self) = @_;
    my $ops = $self->{ops};
    my $width = length( $#$ops );

    my $str = '';
    $str .= sprintf "%*d: %s\n", $width, $_, $ops->[$_]->as_string()
        for 0 .. $#$ops;

    return $str;
}


=item B<addr>( $I<ADDRESS> )

Return the instruction at the given I<ADDRESS>.

=cut

sub addr
{
    my ($self, $addr) = @_;
    return $self->{ops}[$addr];
}


=item B<end>()

Return the address after the last instruction currently in the program.

=cut

sub end
{
    my ($self) = @_;
    return scalar @{ $self->{ops} };
}


# Push a new instruction and any arguments onto the list
sub _push
{
    my ($self, $code, @args) = @_;
    my $op = Regex::Prog::Op->new( $code, @args );
    push @{ $self->{ops} }, $op;
    return $op;
}


=item B<add_match>( $I<CHARACTER> )

Add a C<match> instruction which matches the given I<CHARACTER>.

=cut

sub add_match
{
    my ($self, $char) = @_;
    return $self->_push( 'match', $char );
}


=item B<add_any>()

Add an C<any> instruction which matches any character.

=cut

sub add_any
{
    my ($self) = @_;
    return $self->_push( 'any' );
}


=item B<add_accept>()

Add an C<accept> instruction which causes the program to end successfully.

=cut

sub add_accept
{
    my ($self) = @_;
    return $self->_push( 'accept' );
}


=item B<add_goto>( I<ADDRESS> )

Add a C<goto> instruction which will jump to the given I<ADDRESS>.

=cut

sub add_goto
{
    my ($self, $addr) = @_;
    return $self->_push( 'goto', $addr );
}


=item B<add_split>( $I<ADDRESS1>, $I<ADDRESS2> )

Add a C<split> instruction, which will create new threads for both of the provided I<ADDRESS>es.

=cut

sub add_split
{
    my ($self, $addr_x, $addr_y) = @_;
    return $self->_push( 'split', $addr_x, $addr_y );
}


=item B<add_save>( $I<REGISTER> )

Add a C<save> instruction which will save the current character position into
the executing thread's I<REGISTER>.

=cut

sub add_save
{
    my ($self, $register) = @_;
    return $self->_push( 'save', $register );
}


=back

=cut

1;
