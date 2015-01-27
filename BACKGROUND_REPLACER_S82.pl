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
$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
$ENV{'PGPLOT_DEV'} = '/xs';


open my $inPositions, '<', "result_S82.csv" or die "cannot open result.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};

foreach my $posCount (0 .. scalar @nyuID - 1)
{
print "p${nyuID[$posCount]}_S82.aper.csv","\n";
open my $inPositions_1, '<', "p${nyuID[$posCount]}_S82.aper.csv" or die "cannot open p${nyuID[$posCount]}_S82.aper.csv: $!";

my $input_positions_1 = Text::CSV->new({'binary'=>1});
$input_positions_1->column_names($input_positions_1->getline($inPositions_1));
my $inputs_1 = $input_positions_1->getline_hr_all($inPositions_1);

my @MAG = map {$_->{'MAG_AUTO'}} @{$inputs_1};
my @MAGERR = map {$_->{'MAGERR_AUTO'}} @{$inputs_1};
my @Kron = map {$_->{'KRON_RADIUS'}} @{$inputs_1};
my @X = map {$_->{'X_IMAGE'}} @{$inputs_1};
my @Y = map {$_->{'Y_IMAGE'}} @{$inputs_1};
my @A = map {$_->{'A_IMAGE'}} @{$inputs_1};
my @B = map {$_->{'B_IMAGE'}} @{$inputs_1};
my @THETA = map {$_->{'THETA_IMAGE'}} @{$inputs_1};

#Good image from reduction
my $image = rfits("p${nyuID[$posCount]}_S82.fits"); 

my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$normal->fits_imag($image);
my @dim = dims($image);
print join(',',@dim),"\n";
#join(',',@dim)
my $size_x = $dim[0];
my $size_y = $dim[1];
print "This image is $size_x x $size_y pixels";
print "\n";

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

foreach my $Count (0 .. scalar @Kron - 1)
	{
	$e = (1-((($B[$Count])**2)/(($A[$Count])**2)))**.5;
	$nx_pix = $X[$Count];
	$ny_pix = $Y[$Count];
	$THETA = $deg2rad * -$THETA[$Count];
	$K = $Kron[$Count];
	
	$r_a = 2.5 * $K * $A[$Count];
	$r_b = 2.5 * $K * $B[$Count];

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
$ellipse->wfits("Full_mask.p${nyuID[$posCount]}_S82_1a.fits");  

$ellipse_2->sethdr($image->hdr);
$ellipse_2->wfits("Full_mask.p${nyuID[$posCount]}_S82_1b.fits"); 

#displ masked image
my $Mimage = rfits("Full_mask.p${nyuID[$posCount]}_S82_1b.fits");
my $mask_image = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$mask_image->fits_imag($Mimage,0,1);

#NEW unmasked image
my $Full_masked_image = $image * $Mimage;
$Full_masked_image->sethdr($image->hdr);

#Displ fully masked image
$Full_masked_image->wfits("Full_masked.p${nyuID[$posCount]}_S82.fits");
my $Full_masked = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$Full_masked->fits_imag($Full_masked_image);

#Make a gauss random background generated image from the fully masked image

my $Good_values= $Full_masked_image;
my $masked = $Good_values <= 0;
my $backgroundVals = $Good_values->where(!$masked);
my $maskedVals = $Good_values->where($masked);
$maskedVals .= $backgroundVals->index(randsym($maskedVals)*$backgroundVals->nelem);

$Good_values-> wfits("background.p${nyuID[$posCount]}_S82.fits");
my $average = avg($Good_values);
print $average,"\n";

##Display background image
my $backimage = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
$backimage->fits_imag($Good_values);

}
