package Regex;

=head1 NAME

Regex - Automaton-based regular expressions

=cut

use strict;
use warnings;

use Regex::Engine;
use Regex::Parse;
use Regex::Prog;

our $VERSION = '0.01';


=head1 METHODS

=over 4

=item B<new>( $I<PATTERN> )

Create a new regular expression object from the specified I<PATTERN>.

=cut

sub new
{
    my ($class, $pattern) = @_;

    # prepend .*? so we don't anchor to the start of the string
    # wrap the original pattern in a group to capture the whole thing as group #0
    my $expr = Regex::Parse->parse( ".*?($pattern)" );

    my $obj = {
        pattern => $pattern,
        expr    => $expr,
        program => undef,
        engine  => undef,
    };

    return bless $obj, $class;
}


=item B<match>( $I<STRING> )

Try to match the regex against the I<STRING>, and return true if it succeeds.
In list context, also returns a list of 2-element arrayrefs representing the
positions within the I<STRING> captured by any grouping parentheses in the regex
pattern.

=cut

sub match
{
    my ($self, $string) = @_;
    my $engine = $self->_engine();
    return $engine->execute( $string );
}


=item B<replace>( $I<STRING>, $I<REPLACEMENT> )

Try to match the regex against the I<STRING>, and replace the matched portion
with I<REPLACEMENT> if it succeeds.

=cut

sub replace
{
    my ($self, $string, $replacement) = @_;
    warn "replace not implemented yet!"; # TODO
    return;
}


################################################################################
# End of public API.  Internals below.

sub _program
{
    my ($self) = @_;

    # Lazily compile the program
    if( not defined $self->{program} )
    {
        my $prog = Regex::Prog->new();
        $self->{expr}->compile( $prog );
        $prog->add_accept();
        $self->{program} = $prog;
    }

    return $self->{program};
}


sub _engine
{
    my ($self) = @_;

    # Lazily initialize the virtual machine
    return $self->{engine} ||= Regex::Engine->new( $self->_program() );
}


=back

=cut

1;
