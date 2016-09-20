package Regex::Engine;

=head1 NAME

Regex::Engine - Virtual machine for running compiled Regex programs

=cut

use strict;
use warnings;

use Regex::Engine::Thread;
use Regex::Engine::ThreadQueue;
use Regex::Scanner;


=head1 METHODS

=over 4

=item B<new>( $I<PROGRAM> )

Create a new virtual machine which will run the compiled I<PROGRAM>.

=cut

sub new
{
    my ($class, $prog) = @_;
    my $obj = {
        prog => $prog,
    };

    return bless $obj, $class;
}


=item B<execute>( $I<PROGRAM>, $I<STRING> )

Run the I<PROGRAM> with I<STRING> as its input.  Return true if it matched,
false otherwise.

=cut

sub execute
{
    my ($self, $string) = @_;
    $self->_init( $string );

    my $prog = $self->{prog};
    my $threads = Regex::Engine::ThreadQueue->new( 0 );
    $self->_add_thread( $threads, 0 );

    my $matched;
    CHAR: while( $threads->count() > 0 )
    {
        my $char = $self->_getchar();
        printf "*** char #%d [%s], %d threads\n", $threads->pos(), $char, $threads->count()
            if $ENV{DEBUG};

        my $new_threads = Regex::Engine::ThreadQueue->new( $threads->pos() + 1 );
        THREAD: while( my $thread = $threads->dequeue() )
        {
            my $addr = $thread->addr();
            my $op = $prog->addr( $addr );
            my $code = $op->code();
            printf "  * %d: %s\n", $addr, $op->as_string()
                if $ENV{DEBUG};

            # Any opcodes which actually consume input are processed here.  Ones
            # which only affect the internal state of the engine are handled
            # inside _add_thread, so the relative priority of splits can be
            # preserved.  This allows us to maintain the greedy vs non-greedy
            # distinction for quantifiers.
            if( $code eq 'match' )
            {
                my ($match_char) = $op->args();
                $self->_add_thread( $new_threads, $addr + 1, $thread )
                    if $char eq $match_char;

                # if no match, this thread dies out
            }
            elsif( $code eq 'any' )
            {
                # Only fail if we're out of input; any actual character matches
                $self->_add_thread( $new_threads, $addr + 1, $thread )
                    if $char ne '';
            }
            elsif( $code eq 'range' )
            {
                next THREAD if $char eq '';

                my ($negated, $chars) = $op->args();
                my $success = 0;

                my @chars = split //, $chars;
                for( my $i = 0; $i < $#chars; $i += 2 )
                {
                    $success = 1, last
                        if  $char ge $chars[$i]
                        and $char le $chars[$i + 1];
                }

                $success = not $success if $negated;
                $self->_add_thread( $new_threads, $addr + 1, $thread )
                    if $success;
            }
            elsif( $code eq 'accept' )
            {
                # We have a winner! Save the current best match and move on.
                # Any threads already queued in $new_threads are higher-priority
                # than this one, so run them in the next CHAR loop in case they
                # find a longer greedy match.  Anything after the current thread
                # in this loop is lower-priority, so just exit the current
                # THREAD loop and don't bother processing them.
                $matched = $thread;
                last THREAD;
            }
            else
            {
                die "$self: unrecognized opcode '$code'";
            }
        }

        $threads = $new_threads;
        $self->_advance();
    }

    return defined $matched if not wantarray;

    # convert saved string positions into pairs or undef
    return if not $matched;
    my @captures;
    my $saved = $matched->{saved} || [];
    while( @$saved )
    {
        my $x = shift @$saved;
        my $y = shift @$saved;
        my $pair = (defined $x and defined $y)
            ? [$x, $y]
            : undef;

        push @captures, $pair;
    }

    return 1, @captures;
}


################################################################################
# End of public API.  Internals below.


# Initialize engine state for a new execution.
sub _init
{
    my ($self, $string) = @_;
    $self->{state} = {
        scan => Regex::Scanner->new( $string ),
    };
}


# Return the character at the current position.
sub _getchar
{
    my ($self) = @_;
    return $self->{state}{scan}->peek();
}


# Move the input position ahead by one character.
sub _advance
{
    my ($self) = @_;
    $self->{state}{scan}->advance();
}


# Copy $thread, or create a new one if it's undef
sub _clone
{
    my ($thread, $addr) = @_;
    return $thread
        ? $thread->clone( $addr )
        : Regex::Engine::Thread->new( $addr );
}


# Add a new thread at the specified instruction address.
sub _add_thread
{
    my ($self, $threads, $addr, $parent) = @_;
    return if $threads->seen( $addr );

    my $op = $self->{prog}->addr( $addr );
    printf "  * %d: %s\n", $addr, $op->as_string()
        if $ENV{DEBUG};

    my $code = $op->code();
    if( $code eq 'goto' )
    {
        # immediately jump to the specified address
        my ($next_addr) = $op->args();
        $self->_add_thread( $threads, $next_addr, $parent );
    }
    elsif( $code eq 'split' )
    {
        # jump to both addresses, by adding two new threads
        my @addrs = $op->args();
        $self->_add_thread( $threads, $_, $parent ) for @addrs;
    }
    elsif( $code eq 'save' )
    {
        my $new_parent = _clone( $parent, $addr + 1 );
        my ($register) = $op->args();
        $new_parent->save( $register, $threads->pos() );
        $self->_add_thread( $threads, $new_parent->addr(), $new_parent );
    }
    else
    {
        # We found a code that actually takes input, so queue it up for the next
        # CHAR loop to handle
        $threads->enqueue( _clone( $parent, $addr ) );
    }
}


=back

=cut

1;
