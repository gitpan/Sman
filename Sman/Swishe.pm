package Sman::Swishe;

#$Id: Swishe.pm,v 1.14 2005/08/26 21:40:23 joshr Exp $

use strict;
use warnings;
use File::Temp qw/ tempfile /;
use fields qw(config tempfilestounlink);


# this doesn't need SWISH::API because we're stuffing data 
# in with the swish-e exe directly.

# call like my $smanswishe = new Sman::Swishe($smanconfig);
sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {};
   bless ($self, $class);
   $self->{config} = shift;  #
   return $self;
}        
# writes a config file to a tmp file,
# returns the filename

sub WriteConfigFile {
	my $self = shift;
	my $tmpdir = $self->{config}->GetConfigData("TMPDIR") || "/tmp";
	my ($fh, $filename) = tempfile( "$tmpdir/sman-swish-conf.XXXXX" );
	push(@ {$self->{tempfilestounlink}}, $filename);
		# extra work to make sure this file gets deleted.
	my @names = $self->{config}->GetConfigNames();
	for my $n (@names) {
		#print "Examining $_..\n";
		if($n =~ /^SWISHE_(.+)/i) {
			my ($name, $value) = ($1, $self->{config}->GetConfigData($n));	
			if ($name =~ m/IndexPointer/) { 
				$value =~ s/%V/$Sman::SMAN_DATA_VERSION/; 
			}
			print "Config: $name -> '$value'\n" if $self->{config}->GetConfigData("VERBOSE");
			print $fh "$name $value\n"; 
			#print "Printed '$name $value' to swishe config file\n";
		}
	}
	print $fh $self->_expandaliasesforswisheconf("TITLEALIASES");
	print $fh $self->_expandaliasesforswisheconf("SECALIASES");
	print $fh $self->_expandaliasesforswisheconf("DESCALIASES");
	print $fh $self->_expandaliasesforswisheconf("MANPAGEALIASES");
	
	close($fh) || die "Failure closing temp config file $filename: $!";
	return $filename;
} 
sub _expandaliasesforswisheconf {
	my ($self, $name) = @_;
	(my $swishname = $name) =~ s/ALIASES//;	# strip off ALIASES
	$swishname = lc($swishname);
	$swishname = "swishtitle" if  (lc($swishname) eq "title");	# patchup.
	# our config calls the title prop 'title', to SWISH-E its swishtitle.
	# we did this because swishtitle is SWISH-E's default 'title' meta & prop
	my $val = $self->{config}->GetConfigData($name);
	if ($val) {
		return   "MetaNameAlias      $swishname $val\n" . 
					"PropertyNameAlias  $swishname $val\n"; 
	} 
	return "";
}

# this is handled here, so user DOESN'T delete the file themself
# doesn't get invoked on a CNTRL-C apparently
sub DESTROY {
	my $self = shift;
	for (@ {$self->{tempfilestounlink}} ) {
		(-e $_) && (-f $_) && unlink($_) || warn "Couldn't unlink $_: $!";
	}
}
	
1;

=head1 NAME

Sman::Swishe - Sman backend to build an sman index with swish-e

=head1 SYNOPSIS 

  # Sman::Swishe needs an Sman::Config object to build a 
  # swish-e config file from.
  my $smanconfig = new Sman::Config(); 
  $smanconfig->ReadDefaultConfigFile(); 
  
  # now, get Sman::Swishe to write a config file for SWISH-E
  my $smanswishe = new Sman::Swishe($smanconfig); 
  $swisheconfigfile = $smanswishe->WriteConfigFile();
  
  # use the swisheconfigfile to build an index with
  # (see sman-update), then delete the config file most likely.
	
=head1 DESCRIPTION

This module creates a custom config file for
swish-e to build the sman index with.

=head1 AUTHOR

Josh Rabinowitz <joshr>

=head1 SEE ALSO

L<sman-update>

=cut

