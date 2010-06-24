package MooseX::Attribute::Shorthand;
use strict;
use warnings;
# ABSTRACT: write custom attribute option bundles

use Moose ();
use Scalar::Util qw(reftype);

=head1 SYNOPSIS


=head1 DESCRIPTION


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
