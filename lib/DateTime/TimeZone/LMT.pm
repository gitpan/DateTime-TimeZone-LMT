package DateTime::TimeZone::LMT;

use strict;
use vars qw( $VERSION );

$VERSION = '1.00';

use Params::Validate qw( validate validate_pos SCALAR ARRAYREF BOOLEAN );
use Carp;
use DateTime;
use DateTime::TimeZone;

sub new {
	my $class = shift;
	my %p = validate( @_, { 
		longitude => { type => SCALAR },
		name =>      { type => SCALAR, optional => 1 }
	});
	croak("Your longitude must be between -180 and +180") unless $p{longitude} <= 180 and $p{longitude} >= -180;
	
	my %self = (
		longitude => $p{longitude},
		offset => offset_at_longitude($p{longitude}),
	);
	$self{name} = $p{name} if exists $p{name};
	
	return bless \%self, $class;
}

sub offset_for_datetime{
	my ($self, $dt) = @_;
	return DateTime::TimeZone::offset_as_seconds($self->{offset})
}

sub offset_for_local_datetime{
	my ($self, $dt) = @_;
	return DateTime::TimeZone::offset_as_seconds($self->{offset})
}

sub offset { $_[0]->{offset} }

sub short_name_for_datetime { 'LMT' }
sub name { 
	my $self = shift;
	my $new_name = shift;
	$self->{name} = $new_name if $new_name;
	return $self->{name} 
}

sub longitude { 
	my $self = shift;
	my $new_longitude = shift;
	if ($new_longitude) {	
		croak("Your longitude must be between -180 and +180") 
			unless $new_longitude <= 180 and $new_longitude >= -180;
	
		$self->{longitude} = $new_longitude;
		$self->{offset} = offset_at_longitude($new_longitude);
		
	}
	return $self->{longitude} 
} 


# No, we're not floating (unless on a boat, in which case you'll 
# have to continually modify your longitude. Unless, of course,
# you're heading due north or due south. In which case your
# longitude will not change.
sub is_floating { 0 }

# Not this either. Unless we're on the Prime Meridian (0 deg long)
# in which case we're still not UTC, although we're the same as.
sub is_utc { 0 }

# Nup, these aren't olsons either
sub is_olson { 0 }

# No such thing as DST so we're never in DST
sub is_dst_for_datetime { 0 }

# We're a solar based zone, so for the sake of returning something
# I'm returning 'solar'. If I return 'Local' it could be confused
# with DateTime::TimeZone::Local
sub category  { 'Solar' }

sub make_alias {
	my $self = shift;
	my $name = shift || 'LMT';

	#eval("use DateTime::TimeZone::Alias $name => ".$self->{offset});
	#if (@_) {
		$DateTime::TimeZone::LINKS{ $name } = $self->{offset};
	#}
}

#
# Functions
#

sub offset_at_longitude {
	# A function, not a class method

	my $longitude = shift;
	
	my $offset_seconds = ( $longitude / 180 ) * (12 * 60 * 60);

	return DateTime::TimeZone::offset_as_string( $offset_seconds );
}

=head1 NAME

DateTime::TimeZone::LMT - A Local Mean Time time zone for DateTime

=head1 SYNOPSIS

  use DateTime::TimeZone::LMT

  my $tz_lmt = DateTime::TimeZone::LMT->new( 
    longitude => -174.2342
  );

  $now = DateTime->now( time_zone => $tz_lmt );

  my $tz_office = DateTime::TimeZone::LMT->new(
    name => 'Office',
    longitude => -174.2343
  );

  $tz_office->make_alias;
  
  $now = DateTime->now( time_zone => 'Office' );

  $tz_office->name;
  # Office

  $tz_office->longitude( 45.123 );
  # 45.123

  $tz_office->longitude;
  # 45.123
  

=head1 DESCRIPTION

This module provides a 'Local Mean Time' timezone for DateTime. Using
it you can determine the Mean Time for any location on Earth. Note
however that the Mean Time and the Apparent Time (where the sun is
in the sky) differ from day to day. This module may account for
Local Apparent Time in the future but then again, the Solar:: modules
will probably be a better bet.

If you want more information on the difference between LMT and LAT,
search the www for 'equation of time' or 'ephemeris'.

=head1 CONSTRUCTORS

This module has the following constructor:

=over 4

=item * new( longitude => $longitude_float, name => $name_string )

Creates a new time zone object usable by DateTime. The zone is calculated
to the second for the given longitude. 

An optional name can be given in order to distinguish between multiple 
instances. This is the long name accessable via DateTime.

=back

=head1 ACCESSORS

C<DateTime::TimeZone::LMT> objects provide the following accessor methods:

=over 4

=item * offset_for_datetime( $datetime )

Given an object which implements the DateTime.pm API, this method
returns the offset in seconds for the given datetime.  This takes into
account historical time zone information, as well as Daylight Saving
Time.  The offset is determined by looking at the object's UTC Rata
Die days and seconds.

=item * offset_for_local_datetime( $datetime )

Given an object which implements the DateTime.pm API, this method
returns the offset in seconds for the given datetime.  Unlike the
previous method, this method uses the local time's Rata Die days and
seconds.  This should only be done when the corresponding UTC time is
not yet known, because local times can be ambiguous due to Daylight
Saving Time rules.

=item * name( $new_name_string )

Returns the name of the time zone.  This is "Local Mean Time" unless
the contructor specifies a different name.

If a new name is given, then the object will be changed before being 
returned.

=item * longitude( $new_longitude_float )

Returns the longitude of the time zone.  This is the value specified
in the constructor.

If a new longitude is given, then the object will be changed before
being returned.

=item * short_name_for_datetime( $datetime )

Returns 'LMT' in all circumstances.

It is B<strongly> recommended that you do not rely on short names for
anything other than display. 

=item * create_alias( $alias_name );

Creates an alias that can be called as a string by DateTime methods.

This means you can C<$dt = DateTime->new( time_zone => 'LMT' )> rather
than the normal C<$dt = DateTime->new( time_zone => $lmt )>. This is of
little benefit unless you're accepting a time zone name from a user.

If the optional $alias_name is provided then that will be the alias 
created. Otherwise the alias is 'LMT'. Multiple aliases can be created
from the one object.

If the longitude is changed after an alias is created, then the alias 
B<I<WILL NOT CHANGE>>. The alias does not behave as an instance of 
C<DateTime::TimeZone::LMT>.

=back

=head2 Compatability methods

The following methods always return the same value. They exist in order
to make the LMT time zone compatible with the default C<DateTime::TimeZone>
modules.

=over 4

=item * is_floating

Returns false (0) in all circumstances.

=item * is_utc

Returns false (0) in all circumstances.

=item * is_olson

Returns false (0) in all circumstances.

=item * category

Returns 'Solar' in all circumstances.

=back

=head1 Functions

This class also contains the following function:

=over 4

=item * offset_at_longitude( $longitude )

Given a longitude, this method returns a string offset.

=back

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list.  See http://lists.perl.org/ for more details.

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=datetime%3A%3Atimezone%3A%3Almt
or via email at bug-datetime-timezone-lmt@rt.cpan.org.

=head1 AUTHOR

Rick Measham <rickm@cpan.org> with parts taken from DateTime::TimeZone
by Dave Rolsky <autarch@urth.org>.

=head1 COPYRIGHT

Copyright (C) 2003 Rick Measham.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/


=cut
