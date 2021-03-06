use 5.8.8;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Replay',
    AUTHOR             => q{David Ihnen <davidihnen@gmail.com>},
    VERSION_FROM       => 'lib/Replay.pm',
    ABSTRACT_FROM      => 'lib/Replay.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.8.8,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES =>
        { 'Test::More' => 0, 'Test::More' => 1.001003, 'Test::Most' => 0.33, },
    PREREQ_PM => {
        'Amazon::SNS'                          => '1.2',
        'Amazon::SQS::Simple'                  => '2.04',
        'AnyEvent'                             => '7.12',
        'Config::Locale'                       => '0.05',
        'Data::Dumper'                         => '2.121_08',
        'Data::UUID'                           => '1.217',
        'EV'                                   => '4.17',
        'JSON'                                 => '2.53',
        'JSON::Any'                            => '1.29',
        'MongoDB'                              => 'v1.4.1',
        'MongoDB::OID'                         => 'v1.4.1',
        'Moose'                                => '2.1209',
        'Moose::Util::TypeConstraints'         => '2.1209',
        'MooseX::Storage'                      => '0.46',
        'Readonly'                             => '1.04',
        'Scalar::Util'                         => '1.21',
        'Try::Tiny'                            => '0.11',
        'MooseX::MetaDescription::Meta::Trait' => '0.06',
        'Carp'                                 => '1.3301',
        'Digest::MD5'                          => '2.36',
        'EV'                                   => '4.17',
        'File::Spec'                           => '3.40',
        'List::Util'                           => '1.21',
        'MooseX::MetaDescription::Meta::Trait' => '0.06',
        'Perl::Version'                        => '1.013',
        'POSIX'                                => '1.09',
        'Storable'                             => '2.45',
        'Time::HiRes'                          => '1.9717',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Replay-*' },
);
