package Test::Replay::ReportFilesystem;

use lib 't/lib';

use base qw/Replay::Test/;
use Test::Most qw/bail/;

sub t_environment_reset : Test(startup => 1) {
    my $self = shift;
    `rm -rf $self->{storedir}`;
    ok !-d $self->{storedir};
}

sub a_replay_config : Test(startup) {
    my $self = shift;
    $self->{storedir} = '/tmp/testscript-07-' . $ENV{USER};
    $self->{config}   = {
        stage         => 'testscript-07-' . $ENV{USER},
        EventSystem   => { Mode => 'Null', },
        StorageEngine => { Mode => 'Memory', },
        Defaults      => { ReportEngine => 'Filesystem' },
        ReportEngines => {
            Filesystem =>
                { Mode => 'Filesystem', reportFilesystemRoot => $self->{storedir}, },
        },
        timeout => 10,
    };
}

sub alldone : Test(teardown) {
}

__PACKAGE__->runtests();