#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo::Role;
    use Moose::Role;
    use MooseX::Attribute::Shorthand string => {
        is      => 'ro',
        isa     => 'Str',
        default => sub { $_[1] },
        -meta_attr_options => { isa => 'Str' },
    };

    has foo => (string => 'FOO');
}

{
    package Foo;
    use Moose;
    with 'Foo::Role';
}

my $foo = Foo->new;
is($foo->foo, 'FOO', "expanded properly");
dies_ok { $foo->foo('sldkfj') } "expanded properly";

{
    package Bar::Role;
    use Moose::Role;
    use MooseX::Attribute::Shorthand my_lazy_build => {
        lazy => 1,
        builder => sub { "_build_$_[0]" },
        predicate => sub {
            my $name = shift;
            my $private = $name =~ s/^_//;
            $private ? "_has_$name" : "has_$name";
        },
        clearer => sub {
            my $name = shift;
            my $private = $name =~ s/^_//;
            $private ? "_clear_$name" : "clear_$name";
        },
    };

    has public => (
        is            => 'ro',
        isa           => 'Str',
        my_lazy_build => 1,
    );

    sub _build_public { 'PUBLIC' }

    has _private => (
        is            => 'ro',
        isa           => 'Str',
        my_lazy_build => 1,
    );

    sub _build__private { 'PRIVATE' }
}

{
    package Bar;
    use Moose;
    with 'Bar::Role';
}

my $bar = Bar->new;
can_ok($bar, $_) for qw(has_public clear_public _has_private _clear_private);
ok(!$bar->can($_), "Bar can't $_") for qw(has__private clear__private);

ok(!$bar->has_public, "doesn't have a value yet");
is($bar->public, 'PUBLIC', "gets a lazy value");
ok($bar->has_public, "has a value now");
$bar->clear_public;
ok(!$bar->has_public, "doesn't have a value again");
dies_ok { $bar->public('sldkfj') } "other options aren't overwritten";

ok(!$bar->_has_private, "doesn't have a value yet");
is($bar->_private, 'PRIVATE', "gets a lazy value");
ok($bar->_has_private, "has a value now");
$bar->_clear_private;
ok(!$bar->_has_private, "doesn't have a value again");
dies_ok { $bar->_private('sldkfj') } "other options aren't overwritten";

done_testing;
