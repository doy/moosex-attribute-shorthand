#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;
    use Moose;
    use MooseX::Attribute::Shorthand string => {
        is      => 'ro',
        isa     => 'Str',
        default => sub { $_[1] },
        -meta_attr_options => { isa => 'Str' },
    };

    has foo => (string => 'FOO');
}

my $foo = Foo->new;
is($foo->foo, 'FOO', "expanded properly");
dies_ok { $foo->foo('sldkfj') } "expanded properly";

done_testing;
