package Sman::Man::Cache::DB_File;

#$Id: DB_File.pm,v 1.2 2003/12/29 15:31:41 joshr Exp $

use DB_File;


#@ISA = qw( Sman::Man::Cache );
use base 'Sman::Man::Cache';
use fields qw( dbfile );

# pass a filename to store the DB_File in
sub new {
   my $class = shift;
	my $file = shift;
   my $self = fields::new($class);

   $self->SUPER::new();                # init base fields 

	if (defined($file)) {
		my %totie;
		#tie %totie, "DB_File", $file, O_CREAT|O_RDWR, 0666, $DB_HASH ;
		my $tied = tie %totie, "DB_File", $file, O_CREAT|O_WRONLY, 0666, $DB_HASH ;
		$self->{dbfile} = \%totie;
	}
	return $self;
}

sub get {
	my $self = shift;
	my $key = shift;
	if (defined($self->{dbfile}) && exists($self->{dbfile}->{$key}) ) {
		return $self->{dbfile}->{$key};
	}
	return undef;
}
sub set {
	my $self = shift;
	my $key = shift;	
	# we handle rawdata right from $_[0]. Why not?
	$self->{dbfile}->{$key} = $_[0] if $self->{dbfile};
} 

1;

=head1 NAME

Sman::Man::Cache::DB_File - Cache converted manpages in a DB_File

=head1 SYNOPSIS

  # this module is intended for internal use by sman-update
  my $cache = new Sman::Man::Cache::FileCache();
  $cache->set("[unique name]", "some stuff");
  
  # ..later...
  
  my $ret = $cache->get("[unique name]");
  # $ret will be undef if data not found.
    
=head1 DESCRIPTION

Uses a Cache::Cache subclas to store raw data for use by 
Sman::Man::Convert.
    
=head1 AUTHOR
    
Josh Rabinowitz
    
=head1 SEE ALSO
            
L<sman-update>, L<Sman::Man::Convert>, L<sman.conf>, L<Sman::Man::Cache>
        
=cut    
