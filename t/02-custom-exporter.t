#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    package Foo::Exporter;
    use Moose ();
    use MooseX::Attribute::Shorthand ();
    use Moose::Exporter;

    my ($import) = Moose::Exporter->build_import_methods(
        also    => ['Moose'],
        install => ['unimport'],
    );

    sub import {
        my $class = caller;
        Moose->init_meta(for_class => $class);
        MooseX::Attribute::Shorthand->import(
            -for_class => $class,
            string => {
                is      => 'ro',
                isa     => 'Str',
                default => sub { $_[1] },
                -meta_attr_options => { isa => 'Str' },
            },
        );
        goto $import;
    }
}

{
    package Foo;
    BEGIN { Foo::Exporter->import }

    has foo => (string => 'FOO');
}

my $foo = Foo->new;
is($foo->foo, 'FOO', "got correct options");
dies_ok { $foo->foo('lsdkfj') } "got correct options";

done_testing;
