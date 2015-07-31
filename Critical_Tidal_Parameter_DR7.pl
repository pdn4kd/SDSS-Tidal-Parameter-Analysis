use strict;
use warnings;
#use PGPLOT;
use PDL;
#use PDL::Graphics::PGPLOT;
#use PDL::Graphics2D;
use PDL::Image2D;
#$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
#$ENV{'PGPLOT_DEV'} = '/xs';
use Text::CSV;
#use Astro::IRAF::CL;
#use Cwd qw(cwd);
#use PDL::GSL::RNG;
#use Cwd;
#my $dir = getcwd;
 
 #Creates tidal images for all galaxy images/models.

my @galaxy_fits = qw/1 2 4 a 14/; #model fits we are checking
open my $inPositions, '<', "result_DR7.csv" or die "cannot open result_DR7.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

open my $NOISE, '>', "NOISE_DR7.cl" or die "cannot open NOISE_DR7.cl $!"; # Poisson noise addition
my @nyuID = map {$_->{'col0'}} @{$position_inputs};
foreach my $galaxy_fits (@galaxy_fits) { #iterate over all fit types
#open my $T_plot, '>', "Tp_DR7.csv" or die "cannot open Tp_DR7.csv $!"; # tp table
#print $T_plot "ID,Tp\n";
#open my $displ, '>', "displ_DR7.cl" or die "cannot open displ.cl $!"; # Display images sequentially

foreach my $posCount (0 .. scalar @nyuID - 1) {
if (-e "p${nyuID[$posCount]}_DR7.model_$galaxy_fits.fits") { #Does the output image actually exist?
print "p${nyuID[$posCount]}_DR7.model_$galaxy_fits.fits\n";
#print $displ "p${nyuID[$posCount]}_DR7.fits";

my $Good_values = rfits("background.p${nyuID[$posCount]}_DR7.fits");
my $average = avg($Good_values);
print $average,"\n";

#SCIENCE IMAGES
my $Gimage = rfits("p${nyuID[$posCount]}_DR7.model_$galaxy_fits.fits[1]"); #normal
my $Mimage = rfits("p${nyuID[$posCount]}_DR7.model_$galaxy_fits.fits[2]");
my $Mask_1a = rfits("FMASK.p${nyuID[$posCount]}_DR7.fits");#GALFIT MASK
my $Mask_1b = rfits("FMASK_b.p${nyuID[$posCount]}_DR7.fits"); #normal image mask
my $TMask = rfits("tmask_1a.p${nyuID[$posCount]}_DR7.fits"); #normal image mask

#residual images
my $residual = $Gimage - $Mimage * $Mask_1b;
#$residual->where($residual <= -1 ) .= 0;
$residual -> wfits("residual.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits"); #residual image

#full mask
my $full_mask = $Mask_1b * $TMask;
$full_mask -> wfits("fullmask.p${nyuID[$posCount]}_DR7.fits"); #normal


#model images
my $MODEL_IMAGE;
$MODEL_IMAGE = $Mimage - $average;
$MODEL_IMAGE->wfits("model.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits");
print $NOISE "mknoise model.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits\n";
print $NOISE "imarith model.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits + background.p${nyuID[$posCount]}_DR7.fits bmodel.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits\n";

#-------------------------
#T-Van Dokkum with GALFIT
#-------------------------
#	Science frame calculations with random good sky values 
my $Tp = avg(abs((($Gimage/($Mimage)) - 1)->where($full_mask)));
print "The tidal parameter using GALFIT from van Dokkum et al. 2005 Tp  = ", $Tp, "\n"; 

#Tidal image of galaxy
my $T_image = (($Gimage - $Mimage)/($Mimage) * $full_mask);
#$T_image->where($full_mask <= -1 ) .= 0;
$T_image -> wfits("Timage.p${nyuID[$posCount]}_DR7_$galaxy_fits.fits"); #normal
print "${nyuID[$posCount]}_DR7,$galaxy_fits,$Tp\n";
#print $T_plot "${nyuID[$posCount]}_DR7,$Tp\n";

#my $dim = $T_image->where($full_mask)->nelem;
#my $area = "$dim\n";
#my $aTp = $Tp/$area;

#histograms
#my $hist_Win = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
#$hist_Win->bin(hist($T_image->clump(-1)));
#print $displ "displ p${nyuID[$posCount]}_DR7.model_1.fits[1] 1\n";
#print $displ "displ p${nyuID[$posCount]}_DR7.model_1.fits[2] 2\n";
#print $displ "displ p${nyuID[$posCount]}_DR7.model_1.fits[3] 3\n";
#print $displ "displ residual.p${nyuID[$posCount]}_DR7.fits 4\n";
#print $displ "displ Timage.p${nyuID[$posCount]}_DR7.fits 5\n";
#print $displ "imexam\n";
}
}
}
print"\n";
print "Run NOISE_DR7.cl in IRAF\n";
print "Run GALFIT_MBATCH.sh in a terminal\n";


