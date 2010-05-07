#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

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

my $attr = Foo->meta->get_attribute('foo');
can_ok($attr, 'string');
is($attr->string, 'FOO', "attribute set properly");

done_testing;
