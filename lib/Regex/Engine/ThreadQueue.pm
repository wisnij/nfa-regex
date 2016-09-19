package Regex::Engine::ThreadQueue;

=head1 NAME

Regex::Engine::ThreadQueue - manage the active threads of the engine

=cut

use strict;
use warnings;


=head1 METHODS

=over 4

=item B<new>( $I<POS> )

Create a new, emtpy ThreadQueue for the given string position I<POS>.

=cut

sub new
{
    my ($class, $pos) = @_;
    my $obj = {
        threads => [],
        addrs   => {},
        pos     => $pos,
    };

    return bless $obj, $class;
}


=item B<pos>()

Return the string position this queue is being processed for.

=cut

sub pos
{
    my ($self) = @_;
    return $self->{pos};
}


=item B<count>()

Return the number of threads currently queued.

=cut

sub count
{
    my ($self) = @_;
    return scalar @{ $self->{threads} };
}


=item B<contains>( $I<ADDRESS> )

Return the thread with the given instruction address, if one is queued already.
Returns undef otherwise.

=cut

sub contains
{
    my ($self, $addr) = @_;
    return $self->{addrs}{$addr};
}


=item B<enqueue>( $I<THREAD> )

Adds the thread to the queue, if there isn't one with the same instruction
address already queued.

=cut

sub enqueue
{
    my ($self, $thread) = @_;
    my $addr = $thread->addr();
    return if $self->contains( $addr );

    push @{ $self->{threads} }, $thread;
    $self->{addrs}{$addr} = $self->{threads}[-1];

}


=item B<dequeue>()

Removes the first thread on the queue and returns it.  Returns undef if there
are no threads currently queued.

=cut

sub dequeue
{
    my ($self) = @_;
    my $thread = shift @{ $self->{threads} };
    delete $self->{addrs}{ $thread->addr() }
        if defined $thread;
    return $thread;
}


=item B<seen>( $I<ADDR> )

Return whether a given address has already been seen at this stage of the input.
If it has, don't process it again, because that will cause an infinite loop.
(Avoid the Eternal Return!)

=cut

sub seen
{
    my ($self, $addr) = @_;
    return $self->{seen}{$addr}++;
}


=back

=cut

1;
