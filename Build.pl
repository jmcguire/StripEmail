#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Email::StripEmail',
    license             => 'perl',
    dist_author         => 'Justin McGuire <mcguire-justin@gmail.com>',
    dist_abstract       => 'Strip quoted replies from emails.', # Add just this line
    dist_version_from   => 'lib/Email/StripEmail.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Email-StripEmail-*' ],
);

$builder->create_build_script();


