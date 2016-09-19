#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Regex;

die "Usage: $0 PATTERN [STRING...]\n" if @ARGV < 1;
my ($pat, @inputs) = @ARGV;
my $regex = Regex->new( $pat );

my $pattern = $regex->{pattern};
print "pattern: $pattern\n";

my $expr = $regex->{expr};
printf "expression tree: %s\n", $expr->as_string();

my $prog = $regex->_program();;
print "\ncompiled code:\n";
print $prog->as_string();

for my $i ( 0 .. $#inputs )
{
    my $input = $inputs[$i];
    printf "\nstring %d: %s\n", $i + 1, $input;
    my ($matched, @groups) = $regex->match( $input );

    printf "%s\n", ($matched ? 'match' : 'no match');
    for my $i ( 0 .. $#groups )
    {
        printf "group #%d: ", $i;
        my $match = $groups[$i];
        if( $match )
        {
            my ($b, $e) = @$match;
            my $substr = substr( $input, $b, $e - $b );
            print "[$b,$e] = '$substr'";
        }
        else
        {
            print 'undef';
        }

        print "\n";
    }

}
