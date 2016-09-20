#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
BEGIN { use_ok 'Regex' };

my $tests = [
    # basics
    [ 'a',                'b',                undef ],
    [ 'a',                'a',                [ [0,1] ] ],
    [ 'a',                'abb',              [ [0,1] ] ],
    [ 'a',                'bab',              [ [1,2] ] ],
    [ 'a',                'bba',              [ [2,3] ] ],

    # groups
    [ '(a)',              'a',                [ [0,1], [0,1] ] ],
    [ '(.*(a))',          'bba',              [ [0,3], [0,3], [2,3] ] ],

    # anchors
    [ '^a',               'a',                [ [0,1] ], todo => 1 ],
    [ '^a',               'ab',               [ [0,1] ], todo => 1 ],
    [ '^a',               'ba',               undef, todo => 1 ],
    [ 'a$',               'a',                [ [0,1] ], todo => 1 ],
    [ 'a$',               'ba',               [ [0,1] ], todo => 1 ],
    [ 'a$',               'ab',               undef, todo => 1 ],
    [ '^$',               '',                 [ [0,1] ], todo => 1 ],
    [ '^$',               'a',                undef, todo => 1 ],
    [ '^a$',              'a',                [ [0,1] ], todo => 1 ],
    [ '^a$',              'ab',               undef, todo => 1 ],
    [ '^a$',              'ba',               undef, todo => 1 ],
    [ '^a$',              'bab',              undef, todo => 1 ],

    # character classes
    [ '[abc]',            'a',                [ [0,1] ], todo => 1 ],
    [ '[abc]',            'z',                undef, todo => 1 ],
    [ '[^abc]',           'z',                [ [0,1] ], todo => 1 ],
    [ '[^abc]',           'a',                undef, todo => 1 ],
    [ '[a-z]',            'a',                [ [0,1] ], todo => 1 ],
    [ '[a-z]',            '0',                undef, todo => 1 ],
    [ '[^a-z]',           '0',                [ [0,1] ], todo => 1 ],
    [ '[^a-z]',           'a',                undef, todo => 1 ],
];


sub test
{
    my ($n, $pattern, $input, $expected, %options) = @_;

    my $regex = Regex->new( $pattern );
    isa_ok $regex, 'Regex', "/$pattern/";

    my ($matched, @groups) = $regex->match( $input );
    if( not $expected )
    {
        ok !$matched, "/$pattern/ did not match '$input'";
        return;
    }
    else
    {
        ok $matched, "/$pattern/ matched '$input'";
        is_deeply \@groups, $expected, "match groups"
            or diag( sprintf "expected:\n%s\ngot:\n%s",
                     explain( $expected ), explain( \@groups ) );
    }
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
