use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AEAE',
    AUTHOR              => 'Jerome Eteve <jerome@eteve.net>, Yannick Lesage <yan.lesage@free.fr>',
    VERSION_FROM        => 'lib/AEAE.pm',
    ABSTRACT_FROM       => 'lib/AEAE.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Class::AutoAccess' => 0.02,
	'CGI' => 3.15,
	'CGI::Ajax' => 0.683,
	'POSIX' => 1.05,
	'Data::UUID' => 0.11
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AEAE-*' },
);
