use strict;
use warnings;
use PGPLOT;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::Graphics2D;
use PDL::Image2D;
use PDL::IO::FITS;;
use Text::CSV;
use Math::Trig 'pi';
use PDL::IO::Pic;
use PDL::Core;
use PDL::Graphics::IIS;
my $deg2rad = pi/180.;
use PDL::IO::Misc;
use PDL::Transform;
#use Astro::FITS::Header;
#use Astro::FITS::Header::CFITSIO;
$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
$ENV{'PGPLOT_DEV'} = '/xs';

#NEW MASK USING SEXTRACTOR
open my $inPositions, '<', "test.csv" or die "cannot test.csv: $!"; # input is the hot aperture file for your galaxy,but remove the galaxy from the input file

my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $inputs = $input_positions->getline_hr_all($inPositions);

my @MAG = map {$_->{'MAG_AUTO'}} @{$inputs};
my @MAGERR = map {$_->{'MAGERR_AUTO'}} @{$inputs};
my @Kron = map {$_->{'KRON_RADIUS'}} @{$inputs};
my @X = map {$_->{'X_IMAGE'}} @{$inputs};
my @Y = map {$_->{'Y_IMAGE'}} @{$inputs};
my @A = map {$_->{'A_IMAGE'}} @{$inputs};
my @B = map {$_->{'B_IMAGE'}} @{$inputs};
my @THETA = map {$_->{'THETA_IMAGE'}} @{$inputs};

my $image = rfits('test.fits'); #nyu28101

my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$normal->fits_imag($image);
my @dim = dims($image);
print join(',',@dim),"\n";
#join(',',@dim)
my $size = $dim[0];
print "This image is $size x $size pixels";
print "\n";
#
#------------------------
my $e; #eccentricity
my $nx_pix;
my $ny_pix;
my $r_a;
my $r_b;
my $THETA;
my $K;

my $x = xvals(float(),$size,$size)+1;
my $y = yvals(float(),$size,$size)+1;
my $ellipse = zeroes($size,$size);
my $ellipse_2 = ones($size,$size);

foreach my $posCount (0 .. scalar @MAG - 1)
	{
	$e = (1-((($B[$posCount])**2)/(($A[$posCount])**2)))**.5;
	$nx_pix = $X[$posCount];
	$ny_pix = $Y[$posCount];
	$THETA = $deg2rad * -$THETA[$posCount];
	$K = $Kron[$posCount];
	$r_a = $K * $A[$posCount];
	$r_b = $K * $B[$posCount];
	my $new_x = $x - $nx_pix;
	my $new_y = $y - $ny_pix;
	
	$new_x .= $new_x * cos(($THETA)/pi) - $new_y * sin(($THETA)/pi);
	$new_y .= $new_x * sin(($THETA)/pi) + $new_y * cos(($THETA)/pi);

	my $tmp = ($new_x /$r_a)**2 + ($new_y /$r_b)**2;
	$tmp->where($tmp<=1) .= 1;
	$tmp->where($tmp>1) .= 0;
	$ellipse |= $tmp;

	my $tmp_2 = ($new_x /$r_a)**2 + ($new_y /$r_b)**2;
	$tmp_2->where($tmp_2<=1) .= 0;
	$tmp_2->where($tmp_2>1) .= 1;
	$ellipse_2 &= $tmp_2;
	
	}

$ellipse->sethdr($image->hdr);
$ellipse_2->sethdr($image->hdr);

$ellipse->wfits('unmask.test_1a.fits');  
$ellipse_2->wfits('unmask.test_1b.fits'); 

my $Mimage = rfits('unmask.test_1b.fits');

my $mask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$mask_image->fits_imag($Mimage,0,1);

#NEW unmasked image

my $Un_masked = $image * $Mimage;
$Un_masked->sethdr($image->hdr);

my $UMmask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$Un_masked->wfits('Good.test.fits');
$UMmask_image->fits_imag($Un_masked);
