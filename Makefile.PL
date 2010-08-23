use ExtUtils::MakeMaker;

WriteMakefile (
    AUTHOR        => 'Justin McGuire <mcguire.justin@gmail.com>',
    ABSTRACT      => "Strip quoted replies from email.",
    NAME          => 'Email::StripEmail',
    (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
    PREREQ_PM     => { },
    VERSION_FROM  => 'lib/Email/StripEmail.pm',
);

