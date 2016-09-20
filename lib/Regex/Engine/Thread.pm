package Regex::Engine::Thread;

=head1 NAME

Regex::Engine::Thread - a VM thread and its saved registers

=cut

use strict;
use warnings;


=head1 METHODS

=over 4

=item B<new>( $I<ADDRESS> )

Create a new thread and initialize it to the instruction at the given I<ADDRESS>.

=cut

sub new
{
    my ($class, $addr) = @_;
    $addr ||= 0;

    my $obj = {
        addr  => $addr,
        saved => undef,
        copy  => 0,
    };

    return bless $obj, $class;
}


=item B<addr>()

Return the instruction address associated with this thread.

=cut

sub addr
{
    my ($self) = @_;
    return $self->{addr};
}


=item B<clone>( $I<ADDRESS> )

Create a copy of this thread, with the same state but a different I<ADDRESS>.
Identical thread states may be shared by reference between multiple threads, and
will only be copied wholesale when a change is made.

=cut

sub clone
{
    my ($self, $addr) = @_;
    my $clone = (ref $self)->new( $addr );
    $clone->{saved} = $self->{saved};
    $clone->{copy} = defined $self->{saved};
    return $clone;
}


# Make a local copy of the thread state if necessary
sub _copy_on_write
{
    my ($self) = @_;
    if( $self->{copy} )
    {
        $self->{saved} = [ @{ $self->{saved} } ];
        $self->{copy} = 0;
    }
}


=item B<save>( $I<REGISTER>, $I<VALUE> )

Save the I<VALUE> into the I<REGISTER> belonging to this thread.

=cut

sub save
{
    my ($self, $register, $value) = @_;

    # Most operations are not saves, so share the same arrayref until we have to
    # update to reduce cost of cloning
    $self->_copy_on_write();
    $self->{saved}[$register] = $value;
}


=back

=cut

1;
