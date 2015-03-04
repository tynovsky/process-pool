#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);
use lib catfile($Bin, '../../lib');
use Time::HiRes qw(sleep);
use File::Temp;

if ($^O eq 'MSWin32') {
    plan( skip_all => 'skip tests on windows' );
}
else {
    plan(tests => 2 + 2 * 3);
}

my $dir = File::Temp->newdir();
note $dir;

use_ok('Process::Pool');

my $prepare_cmd = sub {
    my ($num, $cmd) = @{$_[0]};
    open my $f, '>', "$dir/prepare$num";
    print {$f} "prepare worked";
    close $f;
    return $cmd
};

my $cleanup = sub {
    my ($num, $cmd) = @{$_[0]};
    note "command was $cmd";
    open my $f, '>', "$dir/cleanup$num";
    print {$f} "cleanup worked";
    close $f;
    return
};

my $pp = new_ok(
    'Process::Pool',
    [ { prepare_cmd => $prepare_cmd, cleanup => $cleanup } ],
);

my $first_pid  = $pp->run(['1', "ls > $dir/output1"]);
my $second_pid = $pp->run(['2', "ls > $dir/output2"]);

sleep 1; #this sleeps get interrupted by sigchild - so they serve their purpose
sleep 1;

for my $i (1,2) {
    ok(-f "$dir/prepare$i", "prepare $i worked");
    ok(-f "$dir/cleanup$i", "cleanup $i worked");
    ok(-f "$dir/output$i",  "command $i worked");
}
