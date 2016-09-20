package Regex::Parse;

=head1 NAME

Regex::Parse - parse regular expressions

=cut

use strict;
use warnings;

use Regex::Parse::State;
use Regex::Scanner;

my $classes = {
    alpha  => [ ['A','Z'], ['a','z'] ],
    alnum  => [ ['0','9'], ['A','Z'], ['a','z'] ],
    blank  => [ ' ', "\t" ],
    cntrl  => [ ["\x00","\x1F"], "\x7F" ],
    digit  => [ ['0','9'] ],
    graph  => [ ['!','~'] ],
    lower  => [ ['a','z'] ],
    print  => [ [' ','~'] ],
    punct  => [ ['!','/'], [':','@'], ['[','`'], ['{','~'] ],
    space  => [ ["\t","\r"], " "],
    upper  => [ ['A','Z'] ],
    word   => [ ['0','9'], ['A','Z'],'_', ['a','z'] ],
    xdigit => [ ['0','9'], ['A','F'], ['a','f'] ],
};

my $escapes = {
    d => [0, $classes->{digit}],
    w => [0, $classes->{word}],
    s => [0, $classes->{space}],
    a => "\a",
    e => "\e",
    f => "\f",
    n => "\n",
    r => "\r",
    t => "\t",
    v => "\x0B",
};


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
        my ($next, $escaped) = _get_char( $scan );

        if( $escaped )
        {
            if( ref $next eq 'ARRAY' )
            {
                # A backslashed class, like \d
                my ($negated, $ranges) = @$next;
                $state->add_class( $negated, @$ranges );
            }
            else
            {
                # A single character, like \[ or \n
                $state->add_literal( $next );
            }
        }
        elsif( $next eq '+' or $next eq '*' or $next eq '?' )
        {
            # Repetition operator
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
            $state->add_alt();
        }
        elsif( $next eq '(' )
        {
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
            $state->add_close_paren();
        }
        elsif( $next eq '.' )
        {
            $state->add_any();
        }
        elsif( $next eq '[' )
        {
            my ($negated, @ranges) = _parse_class( $scan );
            $state->add_class( $negated, @ranges );
        }
        else
        {
            # Literal character
            $state->add_literal( $next );
        }
    }

    return $state->finish();
}


sub _get_char
{
    my ($scan) = @_;
    my $escaped = 0;

    if( $scan->peek() eq '\\' )
    {
        $scan->advance();

        # a trailing backslash is literal
        return ('\\', 0) if $scan->done();

        $escaped = 1;
    }

    my $char = $scan->peek();
    $scan->advance();

    my $value = $escaped ? $escapes->{$char} : $char;
    if( $escaped and not defined $value )
    {
        # letter backslashes have to mean something
        die "Unrecognized escape sequence '\\$char'"
            if $char =~ /[[:alpha:]]/;

        # any punctuation can be escaped even if not a metacharacter
        $value = $char;
    }

    return $value if not wantarray;
    return ($value, $escaped, $char);
}


sub _parse_class
{
    my ($scan) = @_;

    my $negated = 0;
    if( $scan->peek() eq '^' )
    {
        $negated = 1;
        $scan->advance();
    }

    my (@ranges, $finished);
    while( not $scan->done() )
    {
        # check for the start of a posix class
        if( $scan->peek(0, 2) eq '[:' )
        {
            $scan->advance(2);
            my $class = _parse_posix_class( $scan );
            push @ranges, @$class;
            next;
        }

        # otherwise, this is a literal, either on its own or the start of a range
        my ($next, $escaped) = _get_char( $scan );

        if( $next eq ']' and not $escaped )
        {
            $finished = 1;
            last;
        }

        if( $scan->peek() ne '-' )
        {
            # not the start of a range, so just add a single char/class
            push @ranges, (ref $next ? @$next : $next);
        }
        else
        {
            $scan->advance();

            my $from = $next;
            if( $scan->peek() eq ']' )
            {
                # end of the class, so dash is a literal
                push @ranges, (ref $from ? @$from : $from);
                push @ranges, '-';
            }
            else
            {
                my $to = _get_char( $scan );
                die "Invalid escape character in range" if ref $from or ref $to;
                die "Invalid character range $from-$to" if $to lt $from;
                push @ranges, [$from, $to];
            }
        }

    }

    die "Unmatched [ in pattern"
        if not $finished;

    die "Empty bracketed character class"
        if not @ranges;

    return ($negated, @ranges);
}


sub _parse_posix_class
{
    my ($scan) = @_;

    my $name = '';
    $name .= $scan->peek(), $scan->advance()
        while not $scan->done()
        and $scan->peek(0, 2) ne ':]';

    die "Unterminated character class"
        if $scan->done();

    $scan->advance(2);

    my $class = $classes->{$name};
    die "Unrecognized character class '$name'"
        if not defined $class;

    return $class;
}


=back

=cut

1;
