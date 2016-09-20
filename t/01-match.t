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
    [ '\d',               '0',                [ [0,1] ] ],
    [ '\d',               'a',                [] ],
    [ '\w',               '0',                [ [0,1] ] ],
    [ '\w',               'a',                [ [0,1] ] ],
    [ '\w',               'A',                [ [0,1] ] ],
    [ '\w',               '_',                [ [0,1] ] ],
    [ '\w',               '!',                [] ],
    [ '\s',               ' ',                [ [0,1] ] ],
    [ '\s',               'a',                [] ],
    [ '\D',               '0',                [], todo => 1 ],
    [ '\D',               'a',                [ [0,1] ], todo => 1 ],
    [ '\W',               '0',                [], todo => 1 ],
    [ '\W',               'a',                [], todo => 1 ],
    [ '\W',               'A',                [], todo => 1 ],
    [ '\W',               '_',                [], todo => 1 ],
    [ '\W',               '!',                [ [0,1] ], todo => 1 ],
    [ '\S',               ' ',                [], todo => 1 ],
    [ '\S',               'a',                [ [0,1] ], todo => 1 ],
    [ '\a',               "\a",               [ [0,1] ] ],
    [ '\e',               "\e",               [ [0,1] ] ],
    [ '\f',               "\f",               [ [0,1] ] ],
    [ '\n',               "\n",               [ [0,1] ] ],
    [ '\r',               "\r",               [ [0,1] ] ],
    [ '\t',               "\t",               [ [0,1] ] ],
    [ '\v',               "\x0B",             [ [0,1] ] ],
    [ '\q',               '',                 undef ],

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
    [ '[\t]',             "\t",               [ [0,1] ] ],

    # ranges
    [ '[a-z]',            'a',                [ [0,1] ] ],
    [ '[a-z]',            '0',                [] ],
    [ '[z-a]',            '',                 undef ],
    [ '[^a-z]',           '0',                [ [0,1] ] ],
    [ '[^a-z]',           'a',                [] ],
    [ '[^z-a]',           '',                 undef ],
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
    [ '[\t-\r]',          "\n",               [ [0,1] ] ],
    [ '[\t-\r]',          't',                [] ],
    [ '[\t-\r]',          'r',                [] ],

    # named classes
    [ '[[:alpha:]]',      'a',                [ [0,1] ] ],
    [ '[[:alpha:]]',      '1',                [] ],
    [ '[[:alnum:]]',      'a',                [ [0,1] ] ],
    [ '[[:alnum:]]',      '#',                [] ],
    [ '[[:blank:]]',      ' ',                [ [0,1] ] ],
    [ '[[:blank:]]',      'a',                [] ],
    [ '[[:cntrl:]]',      "\t",               [ [0,1] ] ],
    [ '[[:cntrl:]]',      'a',                [] ],
    [ '[[:digit:]]',      '1',                [ [0,1] ] ],
    [ '[[:digit:]]',      'a',                [] ],
    [ '[[:graph:]]',      'a',                [ [0,1] ] ],
    [ '[[:graph:]]',      ' ',                [] ],
    [ '[[:graph:]]',      "\n",               [] ],
    [ '[[:lower:]]',      'a',                [ [0,1] ] ],
    [ '[[:lower:]]',      'A',                [] ],
    [ '[[:print:]]',      'a',                [ [0,1] ] ],
    [ '[[:print:]]',      ' ',                [ [0,1] ] ],
    [ '[[:print:]]',      "\n",               [] ],
    [ '[[:punct:]]',      '.',                [ [0,1] ] ],
    [ '[[:punct:]]',      'a',                [] ],
    [ '[[:space:]]',      ' ',                [ [0,1] ] ],
    [ '[[:space:]]',      'a',                [] ],
    [ '[[:upper:]]',      'A',                [ [0,1] ] ],
    [ '[[:upper:]]',      'a',                [] ],
    [ '[[:word:]]',       'a',                [ [0,1] ] ],
    [ '[[:word:]]',       '!',                [] ],
    [ '[[:xdigit:]]',     '0',                [ [0,1] ] ],
    [ '[[:xdigit:]]',     'a',                [ [0,1] ] ],
    [ '[[:xdigit:]]',     'g',                [] ],
    [ '[[:badclass:]]',   '',                 undef ],
];


sub test
{
    my ($n, $pattern, $input, $expected, %options) = @_;
    note "test $n: /$pattern/ =~ '$input'";

    my $regex = eval { Regex->new( $pattern ) };
    if( $@ )
    {
        die if $expected;
        pass "threw error: $@";
        return;
    }

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
                fail 'eval test';
            }
        };
    }
}

done_testing();
