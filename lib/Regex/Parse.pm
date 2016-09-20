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
        elsif( $next eq '[' )
        {
            $scan->advance();
            _parse_class( $scan, $state );
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


sub _parse_class
{
    my ($scan, $state) = @_;

    my $negated = 0;
    if( $scan->peek() eq '^' )
    {
        $negated = 1;
        $scan->advance();
    }

    my (@ranges, $finished);
    while( not $scan->done() )
    {
        my $next = $scan->peek();
        $scan->advance();

        if( $next eq ']' )
        {
            $finished = 1;
            last;
        }

        if( $scan->peek() ne '-' )
        {
            # not the start of a range, so just add a single char
            push @ranges, $next;
        }
        else
        {
            $scan->advance();

            my $from = $next;
            my $to   = $scan->peek();

            if( $to eq ']' )
            {
                # end of the class, so dash is a literal
                push @ranges, $from;
                push @ranges, '-';
            }
            else
            {
                $scan->advance();
                push @ranges, [$from, $to];
            }
        }

    }

    die "Unmatched [ in pattern"
        if not $finished;

    die "Empty bracketed character class"
        if not @ranges;

    $state->add_class( $negated, @ranges );
}


=back

=cut

1;
