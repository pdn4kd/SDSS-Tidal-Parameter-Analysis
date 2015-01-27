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


open my $SEX, '<', "result_DR7.csv" or die "cannot open result_DR7.csv: $!";
my $inp = Text::CSV->new({'binary'=>1});
$inp->column_names($inp->getline($SEX));
my $parameter = $inp->getline_hr_all($SEX);

my @nyuID = map {$_->{'col0'}} @{$parameter};

foreach my $posCount (0 .. scalar @nyuID - 1)
{
	
print "p${nyuID[$posCount]}_DR7.fits\n";

#NEW MASK USING SEXTRACTOR
open my $inPositions, '<', "HOTMASK.p${nyuID[$posCount]}_DR7.csv" or die "cannot open HOTMASK.p${nyuID[$posCount]}_DR7.csv: $!";

my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $inputs = $input_positions->getline_hr_all($inPositions);

my @Kron = map {$_->{'KRON_RADIUS'}} @{$inputs};
my @X = map {$_->{'X_IMAGE'}} @{$inputs};
my @Y = map {$_->{'Y_IMAGE'}} @{$inputs};
my @A = map {$_->{'A_IMAGE'}} @{$inputs};
my @B = map {$_->{'B_IMAGE'}} @{$inputs};
my @THETA = map {$_->{'THETA_IMAGE'}} @{$inputs};

my $image = rfits("mask_1.p${nyuID[$posCount]}_DR7.fits"); #IMAGE
my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$normal->fits_imag($image);
my @dim = dims($image);
print join(',',@dim),"\n";
#join(',',@dim)
my $size_x = $dim[0];
my $size_y = $dim[1];
print "This image is $size_x $size_y pixels";
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


my $x = xvals(float(),$size_x,$size_y)+1;
my $y = yvals(float(),$size_x,$size_y)+1;
my $ellipse = zeroes($size_x,$size_y);
my $ellipse_2 = ones($size_x,$size_y);


my $e_xa;
my $e_yb;

foreach my $Count (0 .. scalar @Kron - 1)
	{
	$e = (1-((($B[$Count])**2)/(($A[$Count])**2)))**.5;
	$nx_pix = $X[$Count];
	$ny_pix = $Y[$Count];
	$THETA = $deg2rad * -$THETA[$Count];
	$K = $Kron[$Count];
	
	$r_a = $K * $A[$Count];
	$r_b = $K * $B[$Count];

	my $new_x = $x - $nx_pix;
	my $new_y = $y - $ny_pix;

	my $r_x = $new_x * cos(($THETA)) - $new_y * sin(($THETA));
	my $r_y = $new_x * sin(($THETA)) + $new_y * cos(($THETA));
	
	my $tmp = ($r_x/$r_a)**2 + ($r_y/$r_b)**2;
	$tmp->where($tmp<=1) .= 1; # galfit wants all objects masked with a value of 1
	$tmp->where($tmp>1) .= 0; #galfit only models values in mask image with 0
	$ellipse |= $tmp;

	my $tmp_2 = ($r_x/$r_a)**2 + ($r_y/$r_b)**2;
	$tmp_2->where($tmp_2<=1) .= 0; #this is for our image we will use in GALFIT bad values are 0
	$tmp_2->where($tmp_2>1) .= 1;
	$ellipse_2 &= $tmp_2;
	
	}

$ellipse->sethdr($image->hdr);
$ellipse_2->sethdr($image->hdr);

$ellipse->wfits("hmask_1a.p${nyuID[$posCount]}_DR7.fits");  
$ellipse_2->wfits("hmask_1b.p${nyuID[$posCount]}_DR7.fits"); 


my $HOT_Mimage_A = rfits("hmask_1a.p${nyuID[$posCount]}_DR7.fits");
my $HOT_Mimage_B = rfits("hmask_1b.p${nyuID[$posCount]}_DR7.fits");
my $COLD_Mimage_A = rfits("mask_1a.p${nyuID[$posCount]}_DR7.fits");
my $COLD_Mimage_B = rfits("mask_1b.p${nyuID[$posCount]}_DR7.fits");

my $mask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$mask_image->fits_imag($HOT_Mimage_B,0,1);

my $final_galfit_mask = $COLD_Mimage_A + $HOT_Mimage_A;
$final_galfit_mask->sethdr($image->hdr);
$final_galfit_mask->wfits("FMASK.p${nyuID[$posCount]}_DR7.fits");

my $final_galfit_mask2 = $COLD_Mimage_B * $HOT_Mimage_B;
$final_galfit_mask2->sethdr($image->hdr);
$final_galfit_mask2->wfits("FMASK_b.p${nyuID[$posCount]}_DR7.fits");
my $fmask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$fmask_image->fits_imag($final_galfit_mask2,0,1);

##NEW masked image
my $Un_masked = $image * $HOT_Mimage_B;
#$residual->where($residual <= -1 ) .= 0;
$Un_masked->sethdr($image->hdr);
$Un_masked->wfits("MASKED.p${nyuID[$posCount]}_DR7.fits");
my $UMmask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$UMmask_image->fits_imag($Un_masked);

}
