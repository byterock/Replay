package Replay::StorageEngine::Memory;

use Moose;
use Scalar::Util qw/blessed/;
use Replay::IdKey;

extends 'Replay::BaseStorageEngine';

my $store = {};

override retrieve => sub {
    my ($self, $idkey) = @_;
    super();
    return $store->{ $idkey->collection }{ $idkey->cubby }
        ||= $self->new_document($idkey);
};

# State transition = add new atom to inbox
override absorb => sub {
    my ($self, $idkey, $atom, $meta) = @_;
		$meta ||= {};
    my $state = $store->{ $idkey->collection }{ $idkey->cubby }
        ||= $self->new_document($idkey);

    # unique list of windows
    $state->{windows} = [
        keys %{ { map { $_ => 1 } @{ $state->{windows} }, $idkey->window } } ];

    # unique list of timeblocks
    $state->{timeblocks} = [
        keys %{ { map { $_ => 1 } grep { $_ } @{ $state->{timeblocks} }, $meta->{timeblock} } } ];

    # unique list of ruleversions
    $state->{ruleversions} = [
        values %{
            {   map {
                    my $m = $_;
                    join('+', map { $_ . '-' . $m->{$_} } sort keys %{$m}) => $m;
                } (@{ $state->{ruleversions} }, $meta->{ruleversion})
            }
        }
    ];
    push @{ $state->{inbox} ||= [] }, $atom;
    super();
    return 1;
};

#}}}}}
override checkout => sub {
    my ($self, $idkey) = @_;
    my $hash = $idkey->hash;
    return if exists $self->{checkouts}{$hash};
    $self->{checkouts}{$hash} = $store->{ $idkey->collection }{ $idkey->cubby }
        ||= {};
    $self->{checkouts}{$hash}{desktop} = delete $self->{checkouts}{$hash}{inbox};
    super();
    return $hash, $self->{checkouts}{$hash};
};

override checkin => sub {
    my ($self, $idkey, $uuid, $state) = @_;
    die "not checked out" unless exists $self->{checkouts}{$uuid};
    my $data = delete $self->{checkouts}{$uuid};
    delete $data->{desktop};
    super();
    $store->{ $idkey->collection }{ $idkey->cubby } = $data;
};

override windowAll => sub {
    my ($self, $idkey) = @_;
    return {
        map {
            $store->{ $idkey->collection }{$_}{idkey}{key} =>
                $store->{ $idkey->collection }{$_}{canonical}
            } grep { 0 == index $_, $idkey->windowPrefix }
            keys %{ $store->{ $idkey->collection } }
    };
};
#}}}}}}}}}}}}}}}}}}}}

=head1 NAME

Replay::StorageEngine::Memory - storage implimentation for in-process memory - testing only

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Replay::StorageEngine::Memory->new( ruleSoruce => $rs, eventSystem => $es, config => {...} );

Stores the entire storage partition in package memory space.  Anybody in
this process can access it as if it is a remote storage solution... only
faster.

=head1 OVERRIDES

=head2 retrieve - get document

=head2 absorb - add atom

=head2 checkout - lock and return document

=head2 revert - revert and unlock document

=head2 checkin - update and unlock document

=head2 windowAll - get documents for a particular window

=head1 AUTHOR

David Ihnen, C<< <davidihnen at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-replay at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Replay>.  I will be notified, and then you'

        ll automatically be notified of progress on your bug as I make changes .

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Replay


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Replay>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Replay>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Replay>

=item * Search CPAN

L<http://search.cpan.org/dist/Replay/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 David Ihnen.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;


=head1 STORAGE ENGINE MODEL ASSUMPTIONS

IdKey: object that indicates all the axis of selection for the data requested
Atom: defined by the rule being processed; storage engine shouldn't care about it.

STATE DOCUMENT GENERAL TO STORAGE ENGINE

inbox: [ Array of Atoms ] - freshly arrived atoms are stored here.
canonical: [ Array of Atoms ] - the current reduced 
canonSignature: "SIGNATURE" - a sanity check to see if this canonical has been mucked with
timeblocks: [ Array of input timeblock names ]
ruleversions: [ Array of objects like { name: <rulename>, version: <ruleversion> } ]

STATE DOCUMENT SPECIFIC TO THIS IMPLIMENTATION

db is determined by idkey->ruleversion
collection is determined by idkey->collection
idkey is determined by idkey->cubby

desktop: [ Array of Atoms ] - the previously arrived atoms that are currently being processed
locked: "SIGNATURE" - if this is set, only a worker who knows the signature may update this
lockExpireEpoch: TIMEINT - used in case of processing timeout to unlock the record

STATE TRANSITIONS IN THIS IMPLEMENTATION 

checkout

rename inbox to desktop so that any new absorbs don't get confused with what is being processed

=head1 STORAGE ENGINE IMPLIMENTATION METHODS 

=head2 (state) = retrieve ( idkey )

Unconditionally return the entire state record 

=head2 (success) = absorb ( idkey, message, meta )

Insert a new atom into the indicated state

=head2 (uuid, state) = checkout ( idkey, timeout )

if the record is locked already
  if the lock is expired
    lock with a new uuid
      revert the state by reabsorbing the desktop to the inbox
      clear desktop
      clear lock
      clear expire time
  else 
    return nothing
else
  lock the record atomically so no other processes may lock it with a uuid
    move inbox to desktop
    return the uuid and the new state

=head2 revert  ( idkey, uuid )

if the record is locked with this uuid
  if the lock is not expired
    lock the record with a new uuid
      reabsorb the atoms in desktop
      clear desktop
      clear lock
      clear expire time
  else 
    return nothing, this isn't available for reverting
else 
  return nothing, this isn't available for reverting

=head2 checkin ( idkey, uuid, state )

if the record is locked, (expiration agnostic)
  update the record with the new state
  clear desktop
  clear lock
  clear expire time
else
  return nothing, we aren't allowed to do this

=cut

1;
