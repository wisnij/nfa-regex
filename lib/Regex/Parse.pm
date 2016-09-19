package Regex::Parse;

=head1 NAME

Regex::Parse - parse regular expressions

=cut

use strict;
use warnings;

use Regex::Parse::State;
use Regex::Scanner;


=head1 FUNCTIONS

=over 4

=item B<parse>( $I<PATTERN> )

Parse I<PATTERN> as a regular expression and return a L<Regex::Expr>
object representing the parse tree.

Despite the name "parse", this function itself primarily acts as a lexer.  The
semantic heavy lifting is done by L<Regex::Parse::State>.

=cut

sub parse
{
    my ($class, $string) = @_;
    my $scan = Regex::Scanner->new( $string );
    my $state = Regex::Parse::State->new();

    while( not $scan->done() )
    {
        my $next = $scan->peek();

        if( $next eq '+' or $next eq '*' or $next eq '?' )
        {
            # Repetition operator
            $scan->advance();
            my $greedy = 1;
            if( $scan->peek() eq '?' )
            {
                $greedy = 0;
                $scan->advance();
            }

            $state->add_quant( $next, $greedy );
        }
        elsif( $next eq '|' )
        {
            # Alternation
            $scan->advance();
            $state->add_alt();
        }
        elsif( $next eq '(' )
        {
            $scan->advance();

            my $capturing = 1;
            if( $scan->peek(0, 2) eq '?:' )
            {
                $capturing = 0;
                $scan->advance(2);
            }

            $state->add_open_paren( $capturing );
        }
        elsif( $next eq ')' )
        {
            $scan->advance();
            $state->add_close_paren();
        }
        elsif( $next eq '.' )
        {
            $scan->advance();
            $state->add_any();
        }
        else
        {
            # Literal character
            $scan->advance();
            $state->add_literal( $next );
        }
    }

    return $state->finish();
}


=back

=cut

1;
