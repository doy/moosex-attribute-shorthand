package MooseX::Attribute::Shorthand;
use strict;
use warnings;
# ABSTRACT: write custom attribute option bundles

use Moose ();
use Scalar::Util qw(reftype);

=head1 SYNOPSIS

    package Foo;
    use Moose;
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

=head1 DESCRIPTION

This allows you to bundle up a group of attribute options into a single option,
to make your attributes shorter and easier to read. This is an alternative to
L<MooseX::Attributes::Curried>, which provides alternative exported functions.
The options to allow are passed as a hash to the 'use' statement for this
module, for instance:

    use MooseX::Attribute::Shorthand string       => { ... },
                                     lazy_require => { ... };

The values of this hash will be hashrefs of attribute options that the new
option should be replaced by. Basic options can just replace things statically,
such as:

    use MooseX::Attribute::Shorthand string => {
        is  => 'ro',
        isa => 'Str',
    };

More complicated attribute options can use subrefs as the values, which will be
called, and have their return values used instead:

    use MooseX::Attribute::Shorthand built_string => {
        is      => 'ro',
        isa     => 'Str',
        builder => sub { "_build_$_[0]" },
    };

The subroutine gets the attribute name as the first argument, and the value
given for the option as the second argument:

    use MooseX::Attribute::Shorthand bool_with_default => {
        is      => 'ro',
        isa     => 'Bool',
        default => sub { $_[1] },
    };

Finally, if you want to do more complicated things, you can override attribute
options on the attribute metaclass for the new attribute option. The default is
for the meta-attribute attribute to be "is => 'ro', isa => 'Bool'", so if you
want to be able to pass different types of values to this object, you'll have
to override that, by passing a hashref of options to the -meta_attr_options
key:

    use MooseX::Attribute::Shorthand date_string => {
        is                 => 'ro',
        isa                => 'Str',
        default            => sub { sub { scalar localtime } },
        -meta_attr_options => { isa => 'Str' },
    };

=cut

sub import {
    my $package = shift;
    my %custom_options = @_;
    my $for_class = delete($custom_options{'-for_class'}) || caller;
    my $role = Moose::Meta::Role->create_anon_role(cache => 1);
    for my $option (keys %custom_options) {
        my $meta_options = delete $custom_options{$option}{'-meta_attr_options'};
        $role->add_attribute($option => (
            is  => 'ro',
            isa => 'Bool',
            %{ $meta_options || {} },
        ));
    }
    $role->add_around_method_modifier(_process_options => sub {
        my $orig = shift;
        my $class = shift;
        my ($name, $options) = @_;
        my %new_options;
        for my $option (keys %$options) {
            if (exists($custom_options{$option})) {
                for my $expanded_option (keys %{ $custom_options{$option} }) {
                    my $expanded_val = $custom_options{$option}->{$expanded_option};
                    if (reftype($expanded_val)
                     && reftype($expanded_val) eq 'CODE') {
                        $new_options{$expanded_option} = $expanded_val->(
                            $name, $options->{$option},
                        );
                    }
                    else {
                        $new_options{$expanded_option} = $expanded_val;
                    }
                }
            }
            else {
                $new_options{$option} = $options->{$option};
            }
        }
        # relies on being modified in-place
        %$options = (%$options, %new_options);
        $class->$orig($name, $options);
    });
    Moose::Util::MetaRole::apply_metaroles(
        for => $for_class,
        class_metaroles => {
            attribute => [$role->name],
        },
        role_metaroles => {
            class_attribute => [$role->name],
        }
    );
}

=head1 SEE ALSO

L<MooseX::Attributes::Curried>

=cut

1;
