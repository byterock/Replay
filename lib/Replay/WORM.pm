package Replay::WORM;

use Moose;
use POSIX qw/strftime/;
use File::Spec qw//;
use Scalar::Util qw/blessed/;
use Try::Tiny;
use Time::HiRes qw/gettimeofday/;

has eventSystem => (is => 'ro', required => 1,);
has directory   => (is => 'ro', required => 0, default => '/var/log/replay');
has filehandles => (is => 'ro', isa      => 'HashRef', default => sub { {} });

# dummy implimentation - Log them to a file
sub BUILD {
    my $self = shift;
    mkdir $self->directory unless -d $self->directory;
    $self->eventSystem->origin->subscribe(
        sub {
            my $message = shift;
            my $bundle  = $self->log($message);
            warn "Not a reference $message" unless ref $message;
            if (blessed $message && $message->isa('CargoTel::Message')) {
                push @{ $message->bundles }, $self->bundle;
                $message->receivedTime(+gettimeofday);
            }
            else {
                try {
                    push @{ $message->{bundles} }, $self->bundle;
                    $message->{receivedTime} = gettimeofday;
                }
                catch {
                    warn "unable to push bundle on message?" . $message;
                };
            }
            $self->eventSystem->derived->emit($message);
        }
    );
}

sub serialize {
    my ($self, $message) = @_;
    return $message unless ref $message;
    return JSON->new->encode($message) unless blessed $message;
    return $message->stringify if blessed $message && $message->can('stringify');
    return $message->freeze    if blessed $message && $message->can('freeze');
    return $message->serialize if blessed $message && $message->can('serialize');
    warn "blessed but no serializer found? $message";
}

sub log {
    my $self    = shift;
    my $message = shift;
    $self->filehandle->print($self->serialize($message) . "\n");
}

sub path {
    my $self = shift;
    File::Spec->catfile($self->directory, $self->bundle);
}

sub filehandle {
    my $self = shift;
    return $self->filehandles->{ $self->bundle }
        if exists $self->filehandles->{ $self->bundle }
        && -f $self->filehandles->{ $self->bundle };
    open $self->filehandles->{ $self->bundle }, '>>', $self->path
        or confess "Unable to open " . $self->path . " for append";
    return $self->filehandles->{ $self->bundle };
}

sub bundle {
    my $self = shift;
    return strftime '%Y-%m-%d-%H', localtime time;
}

1;