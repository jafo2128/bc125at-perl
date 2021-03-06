#!/usr/bin/perl

# Copyright (c) 2013 Rikus Goodell. All Rights Reserved.
# This software is distributed free of charge and comes with NO WARRANTY.

use strict;
use warnings;

use Test::More tests => 67;
use Test::Exception;

use FindBin;

unshift @INC, "$FindBin::Bin/../lib";

use Bc125At::Command;

my @tests = qw(
  1.0     00010000 1.000
  01.0    00010000 1.000
  001.0   00010000 1.000
  0001.0  00010000 1.000
  00001.0 00010000 1.000
  00000000000000000000000000001.000000000000000000000 00010000 1.000
  1       00010000 1.000
  2.34    00023400 2.340
  27.5    00275000 27.500
  27.975  00279750 27.975
  136.5    01365000 136.500
  136.50   01365000 136.500
  136.500  01365000 136.500
  136.5000 01365000 136.500
  136.45   01364500 136.450
  464.525  04645250 464.525
  464.5250 04645250 464.525
  464.5125 04645125 464.5125
  1634.525 16345250 1634.525
  5        00050000 5.000
  56       00560000 56.000
  567      05670000 567.000
  5678     56780000 5678.000
  56789    --       --
);

while (my ($human_input, $expect_nonhuman, $expect_back_to_human) = splice(@tests, 0, 3)) {
    my $t = sub {
        my $got_nonhuman = Bc125At::Command::_nonhuman_freq($human_input);
        is $got_nonhuman, $expect_nonhuman, "to nonhuman: $human_input -> $expect_nonhuman";
    
        my $got_human = Bc125At::Command::_human_freq($expect_nonhuman);
        is $got_human, $expect_back_to_human, "to human: $expect_nonhuman -> $expect_back_to_human";
    };
    if ($expect_nonhuman eq '--'){
        throws_ok { $t->() } qr/was not as expected/, "human input $human_input causes a die";
    }
    else {
        $t->();
    }
}

sub _generate_input {
    my $frq = shift;
    return {
        cmd       => 'CIN',
        index     => '1',
        name      => 'Example',
        frq       => $frq,
        mod       => 'NFM',
        ctcss_dcs => '0',
        dly       => '2',
        lout      => '1',
        pri       => '0',
    };
}

for (
    '04630000',
    '0463.0000',
    '0463.000',
    '0463.00',
    '0463.0',
    '0463',
    '463.0000',
    '463.000',
    '463.00',
    '463.0',
    '463',
  )
{
    my $massaged = Bc125At::Command::_massage(_generate_input($_));
    is_deeply $massaged, _generate_input('04630000'), "massage: $_ -> 04630000";
}

for ('00285750', '0028.5750', '0028.575', '028.5750', '028.575', '28.5750', '28.575',) {
    my $massaged = Bc125At::Command::_massage(_generate_input($_));
    is_deeply $massaged, _generate_input('00285750'), "massage: $_ -> 00285750";
}

is_deeply Bc125At::Command::_empty_rowinfo(), 
{
        cmd       => 'CIN',
        index     => undef,
        name      => ' ' x 16,
        frq       => '000.000',
        mod       => 'AUTO',
        ctcss_dcs => '0',
        dly       => '2',
        lout      => '1',
        pri       => '0',
},
"Basic empty rowinfo was as expected";

is_deeply Bc125At::Command::_empty_rowinfo(
    frq => '125.875',
    lout => '0',
    name => 'Foo',
    index => 37,
),
{
        cmd       => 'CIN',
        index     => 37,
        name      => 'Foo',
        frq       => '125.875',
        mod       => 'AUTO',
        ctcss_dcs => '0',
        dly       => '2',
        lout      => '0',
        pri       => '0',
},
"Adjusted empty rowinfo was as expected";
