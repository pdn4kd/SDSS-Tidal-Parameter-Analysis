use strict;
use warnings;
#use PGPLOT;
use PDL;
#use PDL::Graphics::PGPLOT;
#use PDL::Graphics2D;
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
#$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
#$ENV{'PGPLOT_DEV'} = '/xs';

open my $SEX, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!";
my $inp = Text::CSV->new({'binary'=>1});
$inp->column_names($inp->getline($SEX));
my $parameter = $inp->getline_hr_all($SEX);
my @ID = map {$_->{'col0'}} @{$parameter};

open my $Maker, '>', "Mask_Maker_S82.cl" or die "cannot open Mask_Maker_S82.cl: $!"; # run in IRAF
open my $displ, '>', "display_seg_S82.cl" or die "cannot open display_seg_S82.cl: $!"; # run in IRAF
foreach my $posCount (0 .. scalar @ID - 1) {
		if ((-e "p${ID[$posCount]}_S82.fits") && (-e "p${ID[$posCount]}_S82.aper.csv")) { #cutout and apertures exist
		print "p${ID[$posCount]}_S82.fits\n";
		#NEW MASK USING SEXTRACTOR
		open my $inPositions, '<', "${ID[$posCount]}_S82.aper.csv" or die "cannot open p${ID[$posCount]}_S82.aper.csv: $!";
		my $input_positions = Text::CSV->new({'binary'=>1});
		$input_positions->column_names($input_positions->getline($inPositions));
		my $inputs = $input_positions->getline_hr_all($inPositions);

		#Make new varibles using the header (column name) for each column
		#We will use this later to call certian values
		my @N = map {$_->{'NUMBER'}} @{$inputs};
		my @X = map {$_->{'X_IMAGE'}} @{$inputs};
		my @Y = map {$_->{'Y_IMAGE'}} @{$inputs};
		my @ISO_AREA = map {$_->{'ISOAREA_IMAGE'}} @{$inputs};

		##Open your image from a list
		my $image = rfits("p${ID[$posCount]}_S82.fits"); #nyu250588

		print $displ "displ p${ID[$posCount]}_S82.fits 1\n"; #displ
		print $displ "imexam\n"; #make mask_1a for GALFIT 1=bad 0= good

		#Display a image using the perl
		#my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
		#$normal->fits_imag($image);

		#Acquiring the dimensions in an image
		my @dim = dims($image);
		print join(',',@dim),"\n";
		#join(',',@dim)
		my $size_x = $dim[0];
		my $size_y = $dim[1];
		my $x = $dim[0]/2;
		my $y = $dim[1]/2;

		my $x_1 = $x+5;
		my $x_2 = $x-5;
		my $y_1 = $y+5;
		my $y_2 = $y-5;

		print "This image is $size_x x $size_y pixels\n";
		#---------------
		#Renaming Crap for SExtractor 
		#we need to read in information from SExtractor catalogs from each
		# different input file or image.
		# This is a pain in the ass, but its where most of our images cuts and 
		# source positions are taken and stored.
		#--------------
		#Naming varibles for stuff
		my $Area; #ISO AREA for distance
		my $X_A; #NEW X-limit
		my $X_B;
		my $Y_A; #NEW Y-limit
		my $Y_B;
		#-------------------
		#Making a fake image for GALFIT and for visual confirmation
		#-----------------
		my $XXX = xvals(float(),$size_x,$size_y)+1;
		my $YYY = yvals(float(),$size_x,$size_y)+1;
		my $ellipse = zeroes($size_x,$size_y);
		my $ellipse_2 = ones($size_x,$size_y);

		#		FOR ALL THE CRAP!
				foreach my $sexCount (0 .. scalar @N - 1)
				{
					if ($x_1 >= $X[$sexCount]  && ($y_1 >= $Y[$sexCount] && $y_2 <= $Y[$sexCount]) &&
						$x_2 <= $X[$sexCount]  && ($y_1 >= $Y[$sexCount] && $y_2 <= $Y[$sexCount]))
					{
					$Area = sprintf("%.1f",($ISO_AREA[0]**0.5/2));
					print "$N[$sexCount]\n";
					$X_A = $x+$Area;
					$X_B = $x-$Area;
					$Y_A = $y+$Area;
					$Y_B = $y-$Area;
					print $Maker "imcopy p${ID[$posCount]}_S82.fits p${ID[$posCount]}_S82.mask_1a.fits\n"; #make mask_1a for GALFIT 1=bad 0= good
					print $Maker "imcopy p${ID[$posCount]}_S82.fits p${ID[$posCount]}_S82.mask_1b.fits\n"; #Make masking image 1=good 0=bad
					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =0 lower=$N[$sexCount] upper=$N[$sexCount]\n"; #change galaxy to GALFit = 0
					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =1 lower=$N[$sexCount] upper=$N[$sexCount]\n"; #change galaxy to 1

					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =1 lower=1 upper=INDEF\n";
					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =0 lower=-99 upper=0\n";

					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =1 lower=0 upper=0\n";						   #Change sky to 1
					print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =0 lower=2 upper=INDEF\n";
					print $Maker "imarith p${ID[$posCount]}_S82.mask_1b.fits * p${ID[$posCount]}_S82.fits Good.${ID[$posCount]}_S82.fits\n"; #Final math for Good image
					}
		#			elsif ($X_A >= $X[$sexCount]  && ($Y_A >= $Y[$sexCount] && $Y_B <= $Y[$sexCount]) &&
		#			       $X_B <= $X[$sexCount]  && ($Y_A >= $Y[$sexCount] && $Y_B <= $Y[$sexCount]))
		#			{
		#			print "$N[$sexCount]\n";
		#			print "$X_A,$X_B\n";
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =1 lower=$N[$sexCount] upper=$N[$sexCount]\n"; # change galaxy 1
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =1 lower=0 upper=0\n";						   #Change sky to 1
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1b.fits value =0 lower=2 upper=INDEF\n";					   #remove other sources to zero
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =0 lower=$N[$sexCount] upper=$N[$sexCount]\n"; # make sky 0 for GALFIT
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =1 lower=1 upper=INDEF\n";
		#			print $Maker "imreplace p${ID[$posCount]}_S82.mask_1a.fits value =0 lower=-99 upper=0\n";
		#			print $Maker "imarith  p${ID[$posCount]}_S82.mask_1b.fits * p${ID[$posCount]}.fits Good.${ID[$posCount]}.fits\n"; #Final math for Good image
		#			}

				}
			}
	}
print "Finished\n";
