#!/usr/bin/perl

# Copyright 2005-2006 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

use Mail::DKIM::PublicKey;
use Mail::DKIM::Algorithm::dk_rsa_sha1;

package Mail::DKIM::DkSignature;
use base "Mail::DKIM::Signature";
use Carp;

=head1 NAME

Mail::DKIM::DkSignature - a DomainKeys signature header

=head1 CONSTRUCTORS

=cut

sub new {
	my $type = shift;
	my %prms = @_;
	my $self = {};
	bless $self, $type;

	$self->algorithm($prms{'Algorithm'} || "rsa-sha1");
	$self->signature($prms{'Signature'});
	$self->canonicalization($prms{'Method'} || "simple");
	$self->domain($prms{'Domain'});
	$self->headerlist($prms{'Headers'});
	$self->protocol($prms{'Query'} || "dns");
	$self->selector($prms{'Selector'});

	return $self;
}

=head2 parse() - create a new signature from a DomainKey-Signature header

  my $sig = parse Mail::DKIM::DkSignature(
                  "DomainKey-Signature: a=rsa-sha1; b=yluiJ7+0=; c=nofws"
            );

Constructs a signature by parsing the provided DomainKey-Signature header
content. You do not have to include the header name
(i.e. "DomainKey-Signature:")
but it is recommended, so the header name can be preserved and returned
the same way in as_string().

Note: The input to this constructor is in the same format as the output
of the as_string method.

=cut

sub parse
{
	my $class = shift;
	croak "wrong number of arguments" unless (@_ == 1);
	my ($string) = @_;

	# remove line terminator, if present
	$string =~ s/\015\012\z//;

	# remove field name, if present
	my $prefix;
	if ($string =~ /^(domainkey-signature:)(.*)/si)
	{
		# save the field name (capitalization), so that it can be
		# restored later
		$prefix = $1;
		$string = $2;
	}

	my $self = $class->Mail::DKIM::KeyValueList::parse($string);
	$self->{prefix} = $prefix;

	return $self;
}


=head1 METHODS

=cut

=head2 as_string() - the signature header as a string

  print $signature->as_string . "\n";

outputs

  DomainKey-Signature: a=rsa-sha1; b=yluiJ7+0=; c=nofws

As shown in the example, the as_string method can be used to generate
the DomainKey-Signature that gets prepended to a signed message.

=cut

sub as_string
{
	my $self = shift;

	my $prefix = $self->{prefix} || "DomainKey-Signature:";

	return $prefix . $self->Mail::DKIM::KeyValueList::as_string;
}

sub as_string_without_data
{
	croak "as_string_without_data not implemented";
}

sub body_count
{
	croak "body_count not implemented";
}

sub body_hash
{
	croak "body_hash not implemented";
}

=head2 canonicalization() - get or set the canonicalization (c=) field

  $signature->canonicalization("nofws");
  $signature->canonicalization("simple");

  $method = $signature->canonicalization;

Message canonicalization (default is "simple"). This informs the
verifier of the type of canonicalization used to prepare the message for
signing.

=cut

sub canonicalization
{
	my $self = shift;
	croak "too many arguments" if (@_ > 1);

	if (@_)
	{
		$self->set_tag("c", shift);
	}

	return lc($self->get_tag("c")) || "simple";
}	

=head2 domain() - get or set the domain (d=) field

  my $d = $signature->domain;          # gets the domain value
  $signature->domain("example.org");   # sets the domain value

The domain of the signing entity, as specified in the signature.
This is the domain that will be queried for the public key.

=cut

sub domain
{
	my $self = shift;

	if (@_)
	{
		$self->set_tag("d", shift);
	}

	return lc $self->get_tag("d");
}	

sub expiration
{
	croak "expiration not implemented";
}

use MIME::Base64;

sub check_canonicalization
{
	my $self = shift;

	my $c = $self->canonicalization;

	my @known = ("nofws", "simple");
	return unless (grep { $_ eq $c } @known);
	return 1;
}

# checks whether the protocol found on this subject is valid for
# fetching the public key
# returns a true value if protocol is "dns", false otherwise
#
sub check_protocol
{
	my $self = shift;

	my $protocol = $self->protocol;
	return unless $protocol;
	return ($protocol eq "dns");
}

sub get_algorithm_class
{
	my $self = shift;
	croak "wrong number of arguments" unless (@_ == 1);
	my ($algorithm) = @_;

	my $class =
		$algorithm eq "rsa-sha1" ? "Mail::DKIM::Algorithm::dk_rsa_sha1" :
		undef;
	return $class;
}

# get_public_key - same as parent class

sub hash_algorithm
{
	my $self = shift;
	my $algorithm = $self->algorithm;

	return $algorithm eq "rsa-sha1" ? "sha1" : undef;
}

=head2 headerlist() - get or set the signed header fields (h=) field

  $signature->headerlist("a:b:c");

  my $headerlist = $signature->headerlist;

  my @headers = $signature->headerlist;

Signed header fields. A colon-separated list of header field names
that identify the header fields presented to the signing algorithm.

In scalar context, the list of header field names will be returned
as a single string, with the names joined together with colons.
In list context, the header field names will be returned as a list.

=cut

#sub headerlist
# is in Signature.pm

sub identity
{
	my $self = shift;
	croak "cannot change identity on " . ref($self) if @_;
	return "@" . $self->domain;
}

sub method
{
	croak "method not implemented";
}	

=head2 protocol() - get or set the query methods (q=) field

A colon-separated list of query methods used to retrieve the public
key (default is "dns").

=cut

sub protocol {
	my $self = shift;

	(@_) and
		$self->set_tag("q", shift);

	return $self->get_tag("q");
}	

=head2 selector() - get or set the selector (s=) field

The selector subdivides the namespace for the "d=" (domain) tag.

=cut

# same as parent class

=head2 signature() - get or set the signature data (b=) field

The signature data. Whitespace is automatically stripped from the
returned value.

=cut

# same as parent class

sub timestamp
{
	croak "timestamp not implemented";
}

sub version
{
	croak "version not implemented";
}

1;
