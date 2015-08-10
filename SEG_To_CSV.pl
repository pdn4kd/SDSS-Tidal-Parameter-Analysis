use strict;
use warnings;
use Cwd qw(cwd);
use PDL;
my @values;

my $newvalues;
my $line;

opendir my $fdDir, cwd() or die "Unable to open cwd: $!\n"; #opens current working directory 

 my $objectName;

while (my $file = readdir $fdDir)
	{
	chomp $file; 
	next unless $file =~ m/^pnyu(.+)\.seg\.cat$/; # read only files that began with m/^pnyu\ and end with .csv$/ #SDSS_STARS
	

	$objectName = $1;
	print "pnyu$objectName.csv\n";
	
#NUMBER,FLUX_ISO,FLUXERR_ISO,MAG_ISO,MAGERR_ISO,FLUX_ISOCOR,FLUXERR_ISOCOR,MAG_ISOCOR,MAGERR_ISOCOR,
#FLUX_APER,FLUXERR_APER,MAG_APER,MAGERR_APER,FLUX_AUTO,FLUXERR_AUTO,MAG_AUTO,MAGERR_AUTO,FLUX_BEST,
#FLUXERR_BEST,MAG_BEST,MAGERR_BEST,KRON_RADIUS,BACKGROUND,THRESHOLD,ISOAREA_IMAGE,X_IMAGE,Y_IMAGE,
#ALPHA_J2000,DELTA_J2000,A_IMAGE,B_IMAGE,THETA_IMAGE,ELONGATION,ELLIPTICITY,FWHM_IMAGE,FLAGS,CLASS_STAR


open(IN,"<pnyu$objectName.seg.cat");

open(OUT,">pnyu$objectName.seg.csv");

print OUT "NUMBER,FLUX_AUTO,FLUXERR_AUTO,MAG_AUTO,MAGERR_AUTO,KRON_RADIUS,BACKGROUND,THRESHOLD,ISOAREA_IMAGE,X_IMAGE,Y_IMAGE,ALPHA_J2000,DELTA_J2000,A_IMAGE,B_IMAGE,THETA_IMAGE,ELONGATION,ELLIPTICITY,FWHM_IMAGE,FLAGS,CLASS_STAR\n";while ($line = <IN>)
{
@values = &prepLine("",$line,'\s+');
	if ($values[0] ne '#')
	{
	$newvalues = join( ',', @values);
	print OUT "$newvalues \n";
	}
}	
	}

sub prepLine
{
  # Define passed parameters.

  my $fileHandle = $_[0];
  my $line = $_[1];
  my $splitter = $_[2];

  # Declare local variables.

  my @values;

  # Read the line if necessary.

  if ("$fileHandle" ne "")
  {
    $line = <$fileHandle>;
  }

  # Chomp, split, and shift it.

  chomp $line;
  @values = split(/$splitter/,$line);
  if ($values[0] eq "")
  {
    shift @values;
  }

  return @values;
}

