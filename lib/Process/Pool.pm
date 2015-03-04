package Process::Pool;

use strict;
use warnings;
use POSIX ":sys_wait_h";

our $VERSION = "0.01";

my $constructed = 0;

sub new {
    my ($class, $args) = @_;
    die 'only one Process::Pool instance per process allowed' if $constructed;
    $constructed = 1;
    die 'args must be hash' if ref $args ne 'HASH';
    for (qw(prepare_cmd cleanup)) {
        die "missing required argument $_\n" if !defined $args->{$_};
    }
    $args->{children} = {};
    my $self = bless $args, $class;
    $self->register_signal_handler();
    return $self;
}

sub register_signal_handler {
    my ($self) = @_;
    $SIG{CHLD} = sub {
        local ($!, $?);
        while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
            my $process_data = delete $self->{children}{$pid};
            next if !$process_data;
            $self->{cleanup}->($process_data, $?, $pid);
        }
    };
}

sub run {
    my ($self, $process_data) = @_;

    my $cmd = $self->{prepare_cmd}->($process_data);
    my $pid = fork;
    if ($pid) {
        $self->{children}{$pid} = $process_data;
        # print "this is parent $$ of $pid\n";
        return $pid
    }
    elsif ($pid == 0) {
        $SIG{ALRM} = 'IGNORE';
        # print "this is child $$\n";
        exec $cmd;
        exit
    }
    else {
        die 'Unable to fork!';
    }
}

sub size {
    my ($self) = @_;
    return scalar keys %{ $self->{children} };
}

1
__END__

=encoding utf-8

=head1 NAME

Process::Pool - It's new $module

=head1 SYNOPSIS

    use Process::Pool;

=head1 DESCRIPTION

=head1 LICENSE

Copyright (C) Týnovský Miroslav.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Týnovský Miroslav E<lt>tynovsky@avast.comE<gt>

=cut
