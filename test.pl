#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Regex;


# Takes tab-separated input with the format:
#   test_number  pattern  input_string  expected_matches

# Matches are represented in the form (x,y) where x and y are integer string
# positions, or ? for failed matches

while( defined( my $line = <> ) )
{
    chomp $line;
    my ($n, $pattern, $input, $expected) = split / *\t+/, $line;
    $n =~ s/^\s+//;

    my $regex = eval { Regex->new( $pattern ) };
    if( not defined $regex )
    {
        print "$n: error parsing $pattern: $@\n";
        next;
    }

    my ($matched, @groups) = eval { $regex->match( $input ) };
    if( $@ )
    {
        print "$n: error matching $pattern to $input: $@\n";
        next;
    }

    if( not $matched )
    {
        print "$n: $pattern did not match $input\n";
        next;
    }

    #print "$n: matched\n";
    my $got = join '', map { defined $_ ? "($_->[0],$_->[1])" : '(?,?)' } @groups;

    $expected =~ s/(\Q(?,?)\E)+//;
    if( $got ne $expected )
    {
        print "$n: expected: $expected  got: $got  pattern: $pattern  input: $input\n";
    }
    else
    {
        print "$n: ok\n";
    }
}
