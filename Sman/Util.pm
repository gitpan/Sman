################################
package Sman::Util;
use Sman;	# for VERSION

#$Id: Util.pm,v 1.21 2004/06/06 17:08:54 joshr Exp $

use strict;
use warnings;
use Config;	# to get perl version string
use lib '/usr/local/lib/swish-e/perl';
use SWISH::DefaultHighlight; 

sub MakeXML { # output xml version of hash
   my $metas = shift;
   my $xml = join ("", 
   map { "<$_>\n" . XMLEscape($metas->{$_}) . "\n</$_>\n" }
   keys %$metas); 
   my $pre = qq{<?xml version="1.0" standalone="yes"?>\n\n};
   return qq{$pre<all>\n$xml\n</all>\n};
}

sub XMLEscape { 
   return "" unless defined($_[0]); 
	my $v = shift;
   $v =~ s/&/&amp;/g;
	$v =~ s/</&lt;/g;
	$v =~ s/>/&gt;/g;
   return $v;
} 
sub ReadFile { 
	my $file = shift; 
	local( $/, *FFF );	# $/ is set to undef
	open(FFF, "$file") || warn "Couldn't open $file: $!" && return ""; 
	my $content = <FFF>;	# file slurped at once
	close(FFF) || warn "Error closing $file: $!";
	return $content;
} 
sub WriteFile {
	my ($file, $contentref) = @_;
	open(FFF, ">" . "$file") || warn "Couldn't open $file: $!" && return 0;
	print FFF $$contentref;
	close(FFF) || warn "Error closing $file: $!";
	return $contentref; 
}

# RunCommand's block, to encapsulate @tmpfiles.
{
	my @tmpfiles = ();
	# given a command and optional tmpdir, returns (stdout, stderr, $?) 
	# uses the shell underneath
	sub RunCommand {
		my ($cmd, $tmpdir) = @_;
		$tmpdir = "/tmp" unless defined $tmpdir;
		my ($out, $err) = ("", "");
		my $r = sprintf("%04d", rand(9999));
		my ($outfile, $errfile) = ("$tmpdir/cmd" . $$ . "_$r.out", "$tmpdir/cmd" . $$ . "_$r.err");
		my $torun = "$cmd 1> $outfile 2>$errfile";
		push(@tmpfiles, "$outfile", "$errfile");	# in case of SIG
		#print "RUNNING $torun\n";
		system($torun);
		if ($?) {
			my $exit  = $? >> 8;
			my $signal = $? & 127;
			my $dumped = $? & 128;

			$err .= "** ERROR: exitvalue $exit";
			$err .= ", got signal $signal" if $signal;
			$err .= ", dumped core" if $dumped;
			$err .= "\n";
		}
		my $dollarquestionmark = $?;
			
		$out .= ReadFile($outfile);
		$err .= ReadFile($errfile);

		unlink($errfile);
		pop(@tmpfiles);
		unlink($outfile);
		pop(@tmpfiles);

		return ($out, $err, $dollarquestionmark);
	}
	END {	# hopefully this will get triggered 
			# if RunCommand throws an exception
		for my $tmpfile (@tmpfiles) {
			unlink($tmpfile) || warn "** Couldn't unlink tmp file $tmpfile"; 
		}
	}
}

sub GetVersionString {
	my ($prog, $swishecmd) = @_;
	require SWISH::API;	# for $VERSION
	require Sman;		# for $VERSION
	my $str = "$prog " . $Sman::VERSION;
	#$str .=  ' using perl ' . $Config{api_versionstring} . ', SWISH::API ' . $SWISH::API::VERSION . " ";
	$str .=  ' using perl ' . $Config{version} . ', SWISH::API ' . $SWISH::API::VERSION . " ";
	if ($swishecmd) {
		my $cmd = $swishecmd . " -V";
		my @lines = `$cmd`;
		if (defined($lines[0])) {
			chomp($lines[0]);
			($lines[0] =~ / ([\d.]+)/) && ($lines[0] = "SWISH-E $1");
			$str .= "and $lines[0]";
		}
	}
	return $str;
}


sub ExtractSummary {
	my %header = (
		wordcharacters => q{0123456789abcdefghijklmnopqrstuvwxyz});
				#q{ªµºÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß} . 
				#q{àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ});
	my %highlight  = (
		show_words      => 4,    # Number of "swish words" words to show around highlighted word
		max_words       => 10,   # If no words are found to highlighted then show this many words
		occurrences     => 4,     # Limit number of occurrences of highlighted words
		highlight_on   => '*', # highlighting code
		highlight_off  => '*',
	);

	my ($str, $termsref, $prefix, $width) = @_; 
	my $sho = new SWISH::DefaultHighlight( \%highlight, \%header );
	#my $sho = new SWISH::SimpleHighlight( \%highlight, \%header );
	my @phrases;
	for my $t (@$termsref) {
		my @list = ($t);
		push(@phrases, \@list);
	} 
	$sho->highlight(\$str, \@phrases, 'swishdescription');
	$str =~ s/&quot;/'/g;
	$str =~ s/&gt;/>/g;
	$str =~ s/&lt;/</g;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str = $prefix . $str;
	$str = substr($str, 0, $width-3) . "..." if length($str) > $width;
	return $str; 
}

1;

=head1 NAME

Sman::Util - Utility functions for Sman

=head1 SYNOPSIS 

Sman::Util currently provides the following functions:

  # XMLEscape escapes XML
  my $str = Sman::Util::XMLEscape("a-fun#y&%$TRiñg");
  
  # MakeXML makes XML from a simple hash of names->strings
  my $xml = Sman::Util::MakeXML(\%somehash);	
  
  # ReadFile reads the contents of a file and returns it as a scalar
  my $content = Sman::Util::ReadFile("filename"); 
  
  # RunCommand uses the shell to capture stdout and stderr and $?
  # Pass command and tempdir to save its temp files in. 
  # tmpdir defaults to '/tmp'
  my ($out, $err, $dollarquestionmark) = Sman::Util::RunCommand("ls -l", "/tmp"); 

  # GetVersionString gives you a version string like 
  # 'sman v0.8.3 using SWISH::API v0.01 and SWISH-E v2.4.0'
  # pass program name and the swish-e command path
  my $vstr = Sman::Util::GetVersionString('prog', '/usr/local/bin/swish-e');
	
=head1 DESCRIPTION

This module implements utility functions for sman-update and sman

=head1 AUTHOR

Copyright Josh Rabinowitz 2004

=head1 SEE ALSO

L<sman-update>, L<sman>

=cut

