package Regex::Parse::State;

=head1 NAME

Regex::Parse::State - a stack-based parser for regexes

=cut

use strict;
use warnings;

use Regex::Expr;


=head1 METHODS

=over 4

=item B<new>()

Create a new empty parser state.

=cut

sub new
{
    my ($class) = @_;
    my $obj = {
        stack => [],
    };

    return bless $obj, $class;
}


# Return whether the stack is empty.
sub _empty
{
    my ($self) = @_;
    return @{ $self->{stack} } == 0;
}


# Push elements onto the stack
sub _push
{
    my ($self, @items) = @_;
    push @{ $self->{stack} }, @items;
}


# Pop one or more elements off of the stack, and return them in top-to-bottom
# order.
sub _pop
{
    my ($self, $n) = @_;
    $n ||= 1;
    pop @{ $self->{stack} } for 1 .. $n;
}


# Return the element at position $n in the stack, where the top is 1.
sub _nth
{
    my ($self, $n) = @_;
    return $self->{stack}[-$n];
}


# Return the top $n elements from the stack.
sub _top
{
    my ($self, $n) = @_;
    $n ||= 1;
    return $self->_nth( 1 ) if $n == 1;
    return map { $self->_nth( $_ ) } 1 .. $n;
}


# Return a human-readable representation of the stack contents, for debugging.
sub _display_stack
{
    my ($self) = @_;
    my @parts = map { _is_expr($_) ? $_->as_string() : $_->[0] } @{ $self->{stack} };
    return join ', ', @parts;
}


# Return true if the argument is an Expr object of some sort
sub _is_expr
{
    my ($x) = @_;
    return eval { $x->isa( 'Regex::Expr' ) };
}


# Create a temporary mark
sub _mark
{
    my ($type, @args) = @_;
    return [$type, @args];
}


# Return true if the argument is a mark, or is undef.  If $type is provided, the
# mark must be defined and of that type.
sub _is_mark
{
    my ($x, $type) = @_;
    return if _is_expr( $x );
    return (defined $x and $x->[0] eq $type) if defined $type;
    return 1;
}


=item B<add_literal>( $I<CHARACTER> )

Add a literal character to the stack.

=cut

sub add_literal
{
    my ($self, $char) = @_;
    my $expr = Regex::Expr::Literal->new( $char );
    $self->_push( $expr );
}


=item B<add_any>

Add a dot (match any character) to the stack.

=cut

sub add_any
{
    my ($self, $char) = @_;
    my $expr = Regex::Expr::Any->new();
    $self->_push( $expr );
}


=item B<add_class>( $I<NEGATED>, @I<RANGES> )

Add a character class to the stack.

=cut

sub add_class
{
    my ($self, $negated, @ranges) = @_;
    my $expr = Regex::Expr::Class->new( $negated, @ranges );
    $self->_push( $expr );
}


# Concatenate multiple elements from the top of the stack to the first mark
# (alternate, open paren, or bottom of the stack) in preparation for a new mark
# to be added.
sub _finish_concat
{
    my ($self) = @_;
    my ($n1, $n2);
    while( ($n1, $n2) = $self->_top(2)
           and _is_expr( $n1 )
           and _is_expr( $n2 ) )
    {
        $self->_pop(2);

        my $concat = Regex::Expr::Concat->new( $n2, $n1 );
        $self->_push( $concat );
    }

    # If there aren't any Exprs between here and the mark, this must be an
    # expression with an empty term such as (|a).  Add an Empty placeholder so
    # the possibility of matching zero characters is accounted for.
    $self->_push( Regex::Expr::Empty->new() )
        if not _is_expr( $self->_top() );
}


# Combine all alternation choices currently on the stack, until we reach an open
# paren or the bottom of the stack.  E.g. if the top of the stack looks like:
#     expr1
#     '|'
#     expr3
#     '|'
#     expr5
#     ...
# _finish_alt converts it to:
#     Alt(expr5, Alt(expr3, expr1))
#     ...
sub _finish_alt
{
    my ($self) = @_;
    $self->_finish_concat();

    my ($n1, $n2, $n3);
    while( ($n1, $n2, $n3) = $self->_top(3)
           and _is_expr( $n1 )
           and _is_mark( $n2, '|' )
           and _is_expr( $n3 ) )
    {
        $self->_pop(3);

        my $alt = Regex::Expr::Alt->new( $n3, $n1 );
        $self->_push( $alt );
    }
}


=item B<add_alt>()

Add an alternation operator to the stack.

=cut

sub add_alt
{
    my ($self) = @_;
    $self->_finish_concat();
    $self->_push( _mark( '|' ) );
}


=item B<add_quant>( $I<OPERATOR>, $I<GREEDY> )

Add a quantifier (one of C<*>, C<+>, or C<?>) to the stack, including whether it
is greedy or non-greedy.  Throw an error if the stack is empty or the top
element is not something that can be repeated.

=cut

my $quant_classes = {
    '*' => 'Star',
    '+' => 'Plus',
    '?' => 'Ques',
};

sub add_quant
{
    my ($self, $op, $greedy) = @_;
    my $class = $quant_classes->{$op};
    die "unknown quantifier '$op'"
        if not defined $class;

    $class = "Regex::Expr::$class";

    my $top = $self->_top();
    die "stack empty!" if not defined $top;
    die "quantifier '$op' not allowed after " . $self->_display_stack()
        if not _is_expr( $top );
    $self->_pop();

    my $expr = $class->new( $top, $greedy );
    $self->_push( $expr );
}


=item B<add_open_paren>( $I<IS_CAPTURING> )

Add an open paren to the stack.  If I<IS_CAPTURING> is true, this marks the
start of a capture group which will show up in the final expression and capture
substrings from the match.  Otherwise, the group only exists long enough to
disambiguate its contents from the surrounding context.

=cut

sub add_open_paren
{
    my ($self, $capturing) = @_;
    my $group_num = $capturing ? $self->{groups}++ : undef;
    $self->_push( _mark( '(', $capturing, $group_num ) );
}


=item B<add_close_paren>()

Close a previously started group.  Throws an error if no matching open paren is
found.

=cut

sub add_close_paren
{
    my ($self) = @_;
    $self->_finish_alt();
    my ($n1, $n2) = $self->_top(2);
    die "unbalanced ) after " . $self->_display_stack()
        if not (_is_expr( $n1 ) and _is_mark( $n2, '(' ));

    $self->_pop(2);
    if( $n2->[1] )
    {
        # Capturing group
        my $group = Regex::Expr::Group->new( $n1, $n2->[2] );
        $self->_push( $group );
    }
    else
    {
        # Non-capturing group, so just push the subexpression it was enclosing
        # back onto the stack
        $self->_push( $n1 );
    }
}


=item B<finish>()

Finalize the stack and return the finished expression object.  Throw an error if
the stack is in an invalid state (e.g. remaining unbalanced parentheses).

=cut

sub finish
{
    my ($self) = @_;
    $self->_finish_alt();
    die "invalid stack: " . $self->_display_stack()
        if @{ $self->{stack} } > 1;
    return $self->_top();
}


=back

=cut

1;
