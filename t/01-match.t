#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
BEGIN { use_ok 'Regex' };

my $tests = [
    # basics
    [ 'a',                'b',                [] ],
    [ 'a',                'a',                [ [0,1] ] ],
    [ 'a',                'abb',              [ [0,1] ] ],
    [ 'a',                'bab',              [ [1,2] ] ],
    [ 'a',                'bba',              [ [2,3] ] ],

    # groups
    [ '(a)',              'a',                [ [0,1], [0,1] ] ],
    [ '(.*(a))',          'bba',              [ [0,3], [0,3], [2,3] ] ],

    # escapes
    [ '\[',               '[',                [ [0,1] ] ],
    [ '\[',               '\[',               [ [1,2] ] ],
    [ '\\\\',             '\\',               [ [0,1] ] ],
    [ '\\\\',             '\\\\',             [ [0,1] ] ],

    # anchors
    [ '^a',               'a',                [ [0,1] ], todo => 1 ],
    [ '^a',               'ab',               [ [0,1] ], todo => 1 ],
    [ '^a',               'ba',               [], todo => 1 ],
    [ 'a$',               'a',                [ [0,1] ], todo => 1 ],
    [ 'a$',               'ba',               [ [0,1] ], todo => 1 ],
    [ 'a$',               'ab',               [], todo => 1 ],
    [ '^$',               '',                 [ [0,1] ], todo => 1 ],
    [ '^$',               'a',                [], todo => 1 ],
    [ '^a$',              'a',                [ [0,1] ], todo => 1 ],
    [ '^a$',              'ab',               [], todo => 1 ],
    [ '^a$',              'ba',               [], todo => 1 ],
    [ '^a$',              'bab',              [], todo => 1 ],

    # character classes
    [ '[abc]',            'a',                [ [0,1] ] ],
    [ '[abc]',            'z',                [] ],
    [ '[^abc]',           'z',                [ [0,1] ] ],
    [ '[^abc]',           'a',                [] ],

    # ranges
    [ '[a-z]',            'a',                [ [0,1] ] ],
    [ '[a-z]',            '0',                [] ],
    [ '[z-a]',            'a',                undef, todo => 1 ],
    [ '[^a-z]',           '0',                [ [0,1] ] ],
    [ '[^a-z]',           'a',                [] ],
    [ '[^z-a]',           'a',                undef, todo => 1 ],
    [ '[-]',              '-',                [ [0,1] ] ],
    [ '[-a]',             '-',                [ [0,1] ] ],
    [ '[-a]',             'a',                [ [0,1] ] ],
    [ '[a-]',             '-',                [ [0,1] ] ],
    [ '[a-]',             'a',                [ [0,1] ] ],
    [ '[a-z-]',           '-',                [ [0,1] ] ],
    [ '[a-z-1]',          '1',                [ [0,1] ] ],
    [ '[\-]',             '-',                [ [0,1] ] ],
    [ '[\]]',             ']',                [ [0,1] ] ],
    [ '[\--\]]',          ']',                [ [0,1] ] ],

    # named classes
    [ '[[:alpha:]]',      'a',                [ [0,1] ], todo => 1 ],
    [ '[[:alpha:]]',      '1',                [], todo => 1 ],
    [ '[[:alnum:]]',      'a',                [ [0,1] ], todo => 1 ],
    [ '[[:alnum:]]',      '#',                [], todo => 1 ],
    [ '[[:blank:]]',      ' ',                [ [0,1] ], todo => 1 ],
    [ '[[:blank:]]',      'a',                [], todo => 1 ],
    [ '[[:cntrl:]]',      "\t",               [ [0,1] ], todo => 1 ],
    [ '[[:cntrl:]]',      'a',                [], todo => 1 ],
    [ '[[:digit:]]',      '1',                [ [0,1] ], todo => 1 ],
    [ '[[:digit:]]',      'a',                [], todo => 1 ],
    [ '[[:graph:]]',      'a',                [ [0,1] ], todo => 1 ],
    [ '[[:graph:]]',      ' ',                [], todo => 1 ],
    [ '[[:graph:]]',      "\n",               [], todo => 1 ],
    [ '[[:lower:]]',      'a',                [ [0,1] ], todo => 1 ],
    [ '[[:lower:]]',      'A',                [], todo => 1 ],
    [ '[[:print:]]',      'a',                [ [0,1] ], todo => 1 ],
    [ '[[:print:]]',      ' ',                [ [0,1] ], todo => 1 ],
    [ '[[:print:]]',      "\n",               [], todo => 1 ],
    [ '[[:punct:]]',      '.',                [ [0,1] ], todo => 1 ],
    [ '[[:punct:]]',      'a',                [], todo => 1 ],
    [ '[[:space:]]',      ' ',                [ [0,1] ], todo => 1 ],
    [ '[[:space:]]',      'a',                [], todo => 1 ],
    [ '[[:upper:]]',      'A',                [ [0,1] ], todo => 1 ],
    [ '[[:upper:]]',      'a',                [], todo => 1 ],
    [ '[[:word:]]',       'a',                [ [0,1] ], todo => 1 ],
    [ '[[:word:]]',       '!',                [], todo => 1 ],
    [ '[[:xdigit:]]',     '0',                [ [0,1] ], todo => 1 ],
    [ '[[:xdigit:]]',     'a',                [ [0,1] ], todo => 1 ],
    [ '[[:xdigit:]]',     'g',                [], todo => 1 ],
];


sub test
{
    my ($n, $pattern, $input, $expected, %options) = @_;
    note "test $n: /$pattern/ =~ '$input'";

    my $regex = Regex->new( $pattern );
    die "test $n: error expected but none thrown" if not $expected;
    isa_ok $regex, 'Regex', "/$pattern/";

    my ($matched, @groups) = $regex->match( $input );
    if( not @$expected )
    {
        ok !$matched, "/$pattern/ did not match '$input'";
    }
    else
    {
        ok $matched, "/$pattern/ matched '$input'";
    }

    is_deeply \@groups, $expected, "match groups"
        or diag( sprintf "expected:\n%s\ngot:\n%s",
                 explain( $expected ), explain( \@groups ) );
}

for my $i ( 0 .. $#$tests )
{
    my $test = $tests->[$i];
    my ($pattern, $input, $expected, %options) = @$test;
    my $n = $i + 1;

    TODO:
    {
        local $TODO = "skipping test $n", 1 if $options{todo};
        subtest "test $n" => sub {
            eval { test( $n, $pattern, $input, $expected, %options ) };
            if( $@ )
            {
                diag "caught error: $@";
                fail 'eval test' if $expected;
            }
        };
    }
}

done_testing();
