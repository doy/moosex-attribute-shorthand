package MooseX::Attribute::Shorthand;
use strict;
use warnings;

use Scalar::Util qw(reftype);

=head1 NAME

MooseX::Attribute::Shorthand -

=head1 SYNOPSIS


=head1 DESCRIPTION


=cut

sub import {
    my $package = shift;
    my $caller = caller;
    my %custom_options = @_;
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
        %$options = %new_options;
        $class->$orig($name, $options);
    });
    Moose::Util::MetaRole::apply_metaroles(
        for => $caller,
        class_metaroles => {
            attribute => [$role->name],
        },
    );
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-moosex-attribute-shorthand at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooseX-Attribute-Shorthand>.

=head1 SEE ALSO


=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc MooseX::Attribute::Shorthand

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Attribute-Shorthand>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Attribute-Shorthand>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Attribute-Shorthand>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Attribute-Shorthand>

=back

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
