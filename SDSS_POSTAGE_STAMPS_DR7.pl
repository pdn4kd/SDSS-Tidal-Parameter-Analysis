use strict;
use warnings;
use Text::CSV;
use Cwd qw(cwd);
#use String::Scanf;
use Statistics::OLS;
use PDL;
#use PDL::Graphics2D;
use PDL::Constants qw(PI);
use PDL::Fit::Polynomial qw(fitpoly1d);
#use PGPLOT;
#$ENV{PGPLOT_FOREGROUND} = "black";
#$ENV{PGPLOT_BACKGROUND} = "white";


# This script is used to take SDSS x and y outputs and use them as inputs
# for cutting out postage stamps.

open my $inPositions, '<', "result_DR7.csv" or die "cannot open result_DR7.csv: $!"; #Change the input to your input file with the galaxy coordinates
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};
my @px = map {$_->{'imgx'}} @{$position_inputs};
my @py = map {$_->{'imgy'}} @{$position_inputs};
#my @cx = map {$_->{'Xc'}} @{$position_inputs};
#my @cy = map {$_->{'Yc'}} @{$position_inputs};

open my $coutouts, '>', "Galaxy_cutouts_DR7.cl" or die "cannot open Galaxy_cutouts.cl: $!";

foreach my $posCount (0 .. scalar @nyuID - 1)
{
	open my $instars, '<', "$nyuID[$posCount]_DR7.aper.csv" or die "cannot open $nyuID[$posCount]_DR7.aper.csv $!";
	
	my $input_stars = Text::CSV->new({'binary'=>1});
	$input_stars->column_names($input_stars->getline($instars));
	my $galaxy_inputs = $input_stars->getline_hr_all($instars);
	
	#We need to define a set of parameters to make the correct postage stamps
	#These next eight parameters should be usin only 
	#if you dont the position of your galaxies, use the follow eight lines to fine your galaxies
	#in the sextractor catalog with ten pixels in both the X and Y position.
	
	
	#If you do know the exact locations of your galaxies in the SEXtractor catalog
	#then use the 
	
	my @Xp_image; # this will find the galaxies using the x-pixel coordinates of the parent
	my @Yp_image; # this will find the galaxies using the y coordinates of the parent
	# my @Xc_image; # this will find the galaxies using the x-pixel coordinates of the companion
	# my @Yc_image; # this will find the galaxies using the y coordinates of the companion
	
	#parent cutout
	my $Xp_cutout;	
	my $Yp_cutout;
	#imcopy cutout
	my $Xg_p_cutmin;
	my $Xg_p_cutmax;
	my $Yg_p_cutmin;
	my $Yg_p_cutmax;
	
	#companion cutout
	# my $Xc_cutout;	
	# my $Yc_cutout;
	# imcopy cutout
	# my $Xg_c_cutmin;
	# my $Xg_c_cutmax;
	# my $Yg_c_cutmin;
	# my $Yg_c_cutmax;
	#Distance parameters
	# my $Distance_X; #Xp - Xc
	# my $Distance_Y;	#Yp - Yc
	# my $total_X; #Xp + Xc
	# my $total_Y; #Yp + Yc
	
	#total cutout size
	my $Xb;	
	my $Yb;
	my $center;
	my @a_p; # semi-major axis parent galaxies.
	# my @a_c; # semi-major axis companion galaxies.
	my @E_p; # ellipticity of parent galaxies.
	# my @E_c; # ellipticity of companion galaxies.
	my @theta_p;
	# my @theta_c;
	my @Kron_p;
	# my @Kron_c;
	
	#This parameters will deal with the cutout size of the box about the center
	my $Xcenter_cutmin;
	my $Xcenter_cutmax;
	my $Ycenter_cutmin;
	my $Ycenter_cutmax;
	my $X_checker;
	my $Y_checker;
	
	
	#First we need to locate the individual galaxies in the SEXtractor
	#output.
	
	
		@Xp_image = map{$_->{'X_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		@Yp_image = map{$_->{'Y_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		@a_p = map{$_->{'A_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		@Kron_p = map{$_->{'KRON_RADIUS'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		@E_p = map{$_->{'ELLIPTICITY'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		@theta_p = map{$_->{'THETA_IMAGE'}} grep {$_->{'X_IMAGE'} > ($px[$posCount] - 5) && $_->{'X_IMAGE'} < ($px[$posCount] + 5) && $_->{'Y_IMAGE'} > ($py[$posCount] - 5) && $_->{'Y_IMAGE'} < ($py[$posCount] + 5) } @{$galaxy_inputs};
		
		#Correct GALAPAGOS equation would be 2.5x, not 5x
		$Xp_cutout = 5.0 * $a_p[0] * $Kron_p[0] * ( (abs(sin((PI/180) * $theta_p[0]))) + (1 - $E_p[0]) * (abs(cos((PI/180) * $theta_p[0]))) );
		$Yp_cutout = 5.0 * $a_p[0] * $Kron_p[0] * ( (abs(cos((PI/180) * $theta_p[0]))) + (1 - $E_p[0]) * (abs(sin((PI/180) * $theta_p[0]))) );

		my $Xp = sprintf("%.0f", $Xp_image[0]);
		my $Yp = sprintf("%.0f", $Yp_image[0]);
		
		#Sizing cutout to avoid rounding issues
		my $Xp_cut = sprintf("%.0f", $Xp_cutout/2);
		my $Yp_cut = sprintf("%.0f", $Yp_cutout/2);
		
		print "The parent galaxy is located at $Xp,$Yp\n";
			
				if ($Xp_cut > $Yp_cut)
				{
					
				$Xp_cut = $Yp_cut;
				$Xg_p_cutmin = sprintf("%.0f",$Xp - $Xp_cut);
				$Xg_p_cutmax = sprintf("%.0f",$Xp + $Xp_cut);
				$Yg_p_cutmin = sprintf("%.0f",$Yp - $Xp_cut);
				$Yg_p_cutmax = sprintf("%.0f",$Yp + $Xp_cut);
					if ($Xg_p_cutmin > 0 && $Xg_p_cutmax < 2048 && $Yg_p_cutmin > 0 && $Yg_p_cutmax < 1489 )
					{
					print $coutouts "imcopy $nyuID[$posCount]_DR7.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID[$posCount]_DR7.fits\n";
					print "imcopy $nyuID[$posCount]_DR7.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID[$posCount]_DR7.fits\n";					
					}
				}
				else
				{
				$Yp_cut = $Xp_cut;
				$Xg_p_cutmin = sprintf("%.0f",$Xp - $Yp_cut);
				$Xg_p_cutmax = sprintf("%.0f",$Xp + $Yp_cut);
				$Yg_p_cutmin = sprintf("%.0f",$Yp - $Yp_cut);
				$Yg_p_cutmax = sprintf("%.0f",$Yp + $Yp_cut);
					if ($Xg_p_cutmin > 0 && $Xg_p_cutmax < 2048 && $Yg_p_cutmin > 0 && $Yg_p_cutmax < 1489 )
					{
					print $coutouts "imcopy $nyuID[$posCount]_DR7.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID[$posCount]_DR7.fits\n";
					print "imcopy $nyuID[$posCount]_DR7.fits[$Xg_p_cutmin:$Xg_p_cutmax,$Yg_p_cutmin:$Yg_p_cutmax] p$nyuID[$posCount]_DR7.fits\n";
					}
				}

#	Sorting the min and max values to make the correct box size that will be used for center.
	my @Xvalues = sort{$a <=> $b} ($Xg_p_cutmin,$Xg_p_cutmax);
	my @Yvalues = sort{$a <=> $b} ($Yg_p_cutmin,$Yg_p_cutmax);
	
#	the largest box size for both galaxies using the GALAPGOS cutout 
	my $Length_X_image = sprintf("%.0f",(abs($Xvalues[0] - $Xvalues[1])));
	my $Length_Y_image = sprintf("%.0f",(abs($Yvalues[0] - $Yvalues[1])));

	my $Box_Xmin;
	my $Box_Xmax;
	my $Box_Ymin;
	my $Box_Ymax;

}
