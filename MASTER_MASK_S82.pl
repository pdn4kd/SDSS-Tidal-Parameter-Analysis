#! /usr/bin/perl
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

#use Cwd;

#my $dir = getcwd;
#print "$dir\n";


#This script requires four input files: SDSS SQL, SExtractor SDSS full run, SDSS POSTAGE image (cold run), and hot run
open my $SEX, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!"; #Opens the main result.csv that contains all the key parameters

my $inp1 = Text::CSV->new({'binary'=>1});
$inp1->column_names($inp1->getline($SEX));
my $parameter1 = $inp1->getline_hr_all($SEX);

my @nyuID = map {$_->{'col0'}} @{$parameter1}; #ID column
my @Xp = map {$_->{'imgx'}} @{$parameter1}; #X position of galaxy
my @Yp = map {$_->{'imgy'}} @{$parameter1}; #Y position of galaxy
my @petro_mag = map {$_->{'petroMag_r'}} @{$parameter1}; #petrosian magnitude of galaxy
my @petroErr_mag = map {$_->{'petroMagErr_r'}} @{$parameter1}; #petrosian magnitude error
my @model_mag = map {$_->{'modelMag_r'}} @{$parameter1};
my @modelErr_mag = map {$_->{'modelMagErr_r'}} @{$parameter1};
my @Re = map {$_->{'R50_r'}} @{$parameter1};
my @conc_r = map {$_->{'conc_r'}} @{$parameter1};
#my @background_r = map {$_->{'global_background_r'}} @{$parameter1};

open my $DELMAG, '>', "Parameters_S82.csv" or die "cannot open DEL_MAG.csv: $!"; #Magnitude comparison file
print $DELMAG "ID,NUMBER,MAG,MAGErr,petro_mag,petro_magErr,model_mag,model_magErr,X_IMAGE,Y_IMAGE,conc_r,R50\n"; #header for delmag

my $gKron; #This is parameter will be assigned with the orginal galaxy Kron radius multipled by 2.5
foreach my $posCount (0 .. scalar @nyuID - 1) #posCount is counting lines from the result.csv with contains all the SDSS SQL parameters
{
if ((-e "p${nyuID[$posCount]}_S82.fits") && (-e "p${nyuID[$posCount]}_S82.aper.csv")) {
open my $GALFIT_input, '>', "p${nyuID[$posCount]}_S82.galfit_input.csv" or die "cannot open p${nyuID[$posCount]}_S82.galfit_input.csv: $!"; #GALFIt values for objects
print $GALFIT_input "NUMBER,MAG,X,Y,Re,n,THETA,ba,fit,sizex,sizey,type\n"; #header for galfit inputs

open my $COLDMASK, '>', "COLDMASK.p${nyuID[$posCount]}_S82.csv" or die "cannot open COLDMASK.p${nyuID[$posCount]}_S82.galfit_input.csv: $!"; #COLDMASK
print $COLDMASK "NUMBER,X_IMAGE,Y_IMAGE,A_IMAGE,B_IMAGE,THETA_IMAGE,KRON_RADIUS\n";

open my $HOTMASK, '>', "HOTMASK.p${nyuID[$posCount]}_S82.csv" or die "cannot open p${nyuID[$posCount]}_S82.galfit_input.csv: $!"; #HOTMASK
print $HOTMASK "NUMBER,X_IMAGE,Y_IMAGE,A_IMAGE,B_IMAGE,THETA_IMAGE,KRON_RADIUS\n";

open my $Tp_mask, '>', "tidal_mask.${nyuID[$posCount]}_S82.csv" or die "cannot open tidal_mask.${nyuID[$posCount]}_S82.galfit_input.csv: $!"; #Tidal parameter mask
print $Tp_mask "NUMBER,X_IMAGE,Y_IMAGE,A_IMAGE,B_IMAGE,THETA_IMAGE,KRON_RADIUS\n"; #tidal mask parameters

##########################
	#Opens the sextractor catalog and finds coresponding the different sources within them 
	# and places them into different files.
	open my $ALLSEX, '<', "${nyuID[$posCount]}_S82.aper.csv" or die "cannot open ${nyuID[$posCount]}_S82.aper.csv: $!"; #Opens the main all aper.csv that contains all the key parameters
	
	print " This is image ${nyuID[$posCount]}_S82.fits\n ";
	my $inp2 = Text::CSV->new({'binary'=>1});
	$inp2->column_names($inp2->getline($ALLSEX));
	my $parameter2 = $inp2->getline_hr_all($ALLSEX);

	my @N = map {$_->{'NUMBER'}} @{$parameter2};
	my @Kron = map {$_->{'KRON_RADIUS'}} @{$parameter2};
	my @X = map {$_->{'X_IMAGE'}} @{$parameter2};
	my @Y = map {$_->{'Y_IMAGE'}} @{$parameter2};
	my @A = map {$_->{'A_IMAGE'}} @{$parameter2};
	my @B = map {$_->{'B_IMAGE'}} @{$parameter2};
	my @THETA = map {$_->{'THETA_IMAGE'}} @{$parameter2};
	my $GAL_KRON_A;
	my $GAL_KRON_B;
	
	foreach my $allCount (0 .. scalar @Kron - 1) #posCount is counting lines from the result.csv with contains all the SDSS SQL parameters
	{
		if ( $Xp[$posCount] <= ($X[$allCount] + 5 ) && ($Yp[$posCount] < ($Y[$allCount] + 5 ) && $Yp[$posCount] > ($Y[$allCount] - 5 ))
		  && $Xp[$posCount] >= ($X[$allCount] - 5 ) && ($Yp[$posCount] < ($Y[$allCount] + 5 ) && $Yp[$posCount] > ($Y[$allCount] - 5 ))
		   )
		{
			print "Target galaxy is number $N[$allCount] in the entire run catalog and has a kron radius of ";
			$GAL_KRON_A = 2.5 * $Kron[$allCount] * $A[$allCount];
			$GAL_KRON_B = 2.5 * $Kron[$allCount] * $B[$allCount];
			print "$GAL_KRON_A $GAL_KRON_B", "\n"; #This is the important value that we need to make the radius cuts for masking!


#####################
#COLD SEX
				open my $COLDSEX, '<', "p${nyuID[$posCount]}_S82.aper.csv" or die "cannot open p${nyuID[$posCount]}_S82.aper.csv: $!"; #Opens the main cold postage.csv that contains all the key parameters
				print "\n";
				print "Cold SEX p${nyuID[$posCount]}_S82.fits","\n";
				my $inp3 = Text::CSV->new({'binary'=>1});
				$inp3->column_names($inp3->getline($COLDSEX));
				my $parameter3 = $inp3->getline_hr_all($COLDSEX);
			
				my @gN = map {$_->{'NUMBER'}} @{$parameter3};
				my @MAG_AUTO = map {$_->{'MAG_AUTO'}} @{$parameter3};
				my @MAGERR_AUTO = map {$_->{'MAGERR_AUTO'}} @{$parameter3};
				my @gKron = map {$_->{'KRON_RADIUS'}} @{$parameter3};
				my @gX = map {$_->{'X_IMAGE'}} @{$parameter3};
				my @gY = map {$_->{'Y_IMAGE'}} @{$parameter3};
				my @gA = map {$_->{'A_IMAGE'}} @{$parameter3};
				my @gB = map {$_->{'B_IMAGE'}} @{$parameter3};
				my @gTHETA = map {$_->{'THETA_IMAGE'}} @{$parameter3};
				my @gCLASS_STAR = map {$_->{'CLASS_STAR'}} @{$parameter3};
				my @gFWHM = map {$_->{'FWHM_IMAGE'}} @{$parameter3};
				my @ba = map {$_->{'B_IMAGE'}/$_->{'A_IMAGE'}} @{$parameter3};
				my $ba_rounded;
				my $image = rfits("p${nyuID[$posCount]}_S82.fits"); #IMAGE
				#my $normal = PDL::Graphics2D->new('PGPLOT', {'device' => '/xs'});
				#$normal->fits_imag($image);
				my @dim = dims($image);
				#print join(',',@dim),"\n";
				#join(',',@dim)
				my $size_x = $dim[0];
				my $size_y = $dim[1];
				my $midx = sprintf("%.0f",($size_x/2));
				my $midy = sprintf("%.0f",($size_y/2));
				my $starKron;
								
				foreach my $ColdCount (0 .. scalar @gKron - 1) #ColdCount is counting lines from the cold.csv with contains the kron radius for the search condition for the Coldrun 
				{ 
					my $ba_rounded = sprintf("%.3f",$ba[$ColdCount]);					
					#IF STATEMENT FOR FINDING SOURCES INSIDE OF 2.5 x KRON
					if ( $gX[$ColdCount] <= ($midx + $GAL_KRON_A) && ($gY[$ColdCount] <= ($midy + $GAL_KRON_A) && $midy >= ($gY[$ColdCount] - $GAL_KRON_A))
	 				  && $gX[$ColdCount] >= ($midx - $GAL_KRON_A) && ($gY[$ColdCount] <= ($midy + $GAL_KRON_A) && $midy >= ($gY[$ColdCount] - $GAL_KRON_A))
					  || $gX[$ColdCount] <= ($midx + $GAL_KRON_B) && ($gY[$ColdCount] <= ($midy + $GAL_KRON_B) && $midy >= ($gY[$ColdCount] - $GAL_KRON_B))
					  && $gX[$ColdCount] >= ($midx - $GAL_KRON_B) && ($gY[$ColdCount] <= ($midy + $GAL_KRON_B) && $midy >= ($gY[$ColdCount] - $GAL_KRON_B))
			   			) 
					{
								if ( $gX[$ColdCount] <= ($midx + 5 ) && ($gY[$ColdCount] < ($midy + 5 ) && $gY[$ColdCount] > ($midy - 5 )) #GALAXY IS AT THE CENTER OF IMAGE
						  		  && $gX[$ColdCount] >= ($midx - 5 ) && ($gY[$ColdCount] < ($midy + 5 ) && $gY[$ColdCount] > ($midy - 5 )) 
						  		  || $gY[$ColdCount] <= ($midy + 5 ) && ($gX[$ColdCount] < ($midx + 5 ) && $gX[$ColdCount] > ($midx - 5 )) 
						  		  && $gY[$ColdCount] >= ($midy - 5 ) && ($gX[$ColdCount] < ($midx + 5 ) && $gX[$ColdCount] > ($midx - 5 ))
						   			)
								{
								print "Target GALAXY is number $N[$ColdCount] in the Cold SExtractor catalog.\n";
								#PRINT OUT TO GAFIT INPUTS
								print $GALFIT_input "$gN[$ColdCount]c,$MAG_AUTO[$ColdCount],$gX[$ColdCount],$gY[$ColdCount],$Re[$posCount],4,$gTHETA[$ColdCount],$ba_rounded,1,$size_x,$size_y,sersic\n";	
												#ID,NUMBER,MAG,MAGErr,petro_mag,petro_magErr,model_mag,model_magErr,X_IMAGE,Y_IMAGE,conc_r,R50\n
								print $DELMAG "$nyuID[$posCount],$gN[$ColdCount]c,$MAG_AUTO[$ColdCount],$MAGERR_AUTO[$ColdCount],$petro_mag[$posCount],$petroErr_mag[$posCount],$model_mag[$posCount],$modelErr_mag[$posCount],$gX[$ColdCount],$gY[$ColdCount],$Re[$posCount],$conc_r[$posCount]\n"; #header for delmag																				
								print $Tp_mask "$gN[$ColdCount],$gX[$ColdCount],$gY[$ColdCount],$gA[$ColdCount],$gB[$ColdCount],$gTHETA[$ColdCount],$gKron[$ColdCount]\n";
								} #CLOSE GALAXY SEARCH CONDITIONS 

								else #print other sources inside gkron radius
								{
									print "Other sources inside 2.5 x GAL_Kron raduis.","\n";
									if ($gCLASS_STAR[$ColdCount] >= 0.9) # Find Stars in the objects inside of kron radius
									{
									print "$gN[$ColdCount] is a STAR!", "\n"; # We need to find these stars and tell GALFIT TO FIT THEM WITH A PSF
									#Print to GALFIT INPUT with PSF fit
									print $GALFIT_input "$gN[$ColdCount]c,$MAG_AUTO[$ColdCount],$gX[$ColdCount],$gY[$ColdCount],$gFWHM[$ColdCount],4,$gTHETA[$ColdCount],$ba_rounded,1,$size_x,$size_y,psf\n";
									}	
									else # print the reminding sources inside kron radius
									{
									print "$gN[$ColdCount]c is a source inside of the galaxies 2.5 x kron radius! This will be in the GALFIT input file with sersic set to free","\n";
									print $GALFIT_input "$gN[$ColdCount]c,$MAG_AUTO[$ColdCount],$gX[$ColdCount],$gY[$ColdCount],$gFWHM[$ColdCount],4,$gTHETA[$ColdCount],$ba_rounded,1,$size_x,$size_y,sersic\n";
									}
								} #Close else statement for unmasking all the mask sources
							
					} #Close UNMASKING CONDITIONS 
					
					else #this else statement will output all the sources outside of the 2.5 x kron radius to the ColdMask output
					{
						print "The other objects outside of the kron radii are $gN[$ColdCount]\n" ;
									if ($gCLASS_STAR[$ColdCount] >= 0.9) #find all stars outside gkron
									{
									print "Star outside of the kron radius\n";
									$starKron = 1.5 * $gKron[$ColdCount];
									print $COLDMASK "$gN[$ColdCount]c,$gX[$ColdCount],$gY[$ColdCount],$gA[$ColdCount],$gB[$ColdCount],$gTHETA[$ColdCount],$starKron\n";	
									}
									else #print out the other sources
									{
									print " Masking all other sources","\n";
									print $COLDMASK "$gN[$ColdCount]c,$gX[$ColdCount],$gY[$ColdCount],$gA[$ColdCount],$gB[$ColdCount],$gTHETA[$ColdCount],$gKron[$ColdCount]\n";
									}
					} # Close the masking else statement
				} #close ColdAper				

####################
###HOTSEX
				open my $HOTSEX, '<', "hp${nyuID[$posCount]}_S82.aper.csv" or die "cannot open hp${nyuID[$posCount]}_S82.aper.csv: $!"; #Opens the main HOT postage.csv that contains all the key parameters
				print "\n";
				print "HOT SEX SOURCE p${nyuID[$posCount]}_S82.fits","\n";
				my $inp4 = Text::CSV->new({'binary'=>1});
				$inp4->column_names($inp4->getline($HOTSEX));
				my $parameter4 = $inp4->getline_hr_all($HOTSEX);
			
				my @h_N = map {$_->{'NUMBER'}} @{$parameter4};
				my @h_MAG_AUTO = map {$_->{'MAG_AUTO'}} @{$parameter4};
				my @h_Kron = map {$_->{'KRON_RADIUS'}} @{$parameter4};
				my @h_X = map {$_->{'X_IMAGE'}} @{$parameter4};
				my @h_Y = map {$_->{'Y_IMAGE'}} @{$parameter4};
				my @h_A = map {$_->{'A_IMAGE'}} @{$parameter4};
				my @h_B = map {$_->{'B_IMAGE'}} @{$parameter4};
				my @h_THETA = map {$_->{'THETA_IMAGE'}} @{$parameter4};
				my @h_CLASS_STAR = map {$_->{'CLASS_STAR'}} @{$parameter4};
				my @h_FWHM = map {$_->{'FWHM_IMAGE'}} @{$parameter4};
				my @h_ba = map {$_->{'B_IMAGE'}/$_->{'A_IMAGE'}} @{$parameter4};
				my $h_ba_rounded;
				my $h_kronstar;
				my $i;
				my $j;
$i=0;
$j=0;
		
			foreach my $HOTCount (0 .. scalar @h_Kron - 1) #HOTCount is counting lines from the HOT.csv with contains the kron radius for the search condition for the HOTrun 
			{
 				foreach my $ColdCount (0 .. scalar @gKron - 1) #ColdCount is counting lines from the cold.csv with contains the kron radius for the search condition for the Coldrun 
				{$j++;	
					my $h_ba_rounded = sprintf("%.3f",$h_ba[$HOTCount]);	

					  if ($h_X[$HOTCount] <= ($midx + $GAL_KRON_A) && ($h_Y[$HOTCount] <= ($midy + $GAL_KRON_A) && $h_Y[$HOTCount] >= ($midy - $GAL_KRON_A))
					  && $h_X[$HOTCount] >= ($midx - $GAL_KRON_A) && ($h_Y[$HOTCount] <= ($midy + $GAL_KRON_A) && $h_Y[$HOTCount] >= ($midy - $GAL_KRON_A))
					  || $h_X[$HOTCount] <= ($midx + $GAL_KRON_B) && ($h_Y[$HOTCount] <= ($midy + $GAL_KRON_B) && $h_Y[$HOTCount] >= ($midy - $GAL_KRON_B))
					  && $h_X[$HOTCount] >= ($midx - $GAL_KRON_B) && ($h_Y[$HOTCount] <= ($midy + $GAL_KRON_B) && $h_Y[$HOTCount] >= ($midy - $GAL_KRON_B))
						)
				{
				if ( sprintf("%.0f",$h_X[$HOTCount]) <= sprintf("%.0f",$gX[$ColdCount]) + 5 && (sprintf("%.0f",$h_Y[$HOTCount]) <= sprintf("%.0f",$gY[$ColdCount] + 5) && $h_Y[$HOTCount] >= $gY[$ColdCount] - 5)
	 			&& sprintf("%.0f",$h_X[$HOTCount]) >= sprintf("%.0f",$gX[$ColdCount]) - 5 && (sprintf("%.0f",$h_Y[$HOTCount]) <= sprintf("%.0f",$gY[$ColdCount] + 5) && $h_Y[$HOTCount] >= $gY[$ColdCount] - 5)
				    )
					{
					print "Cold Run sources matched in Hot Run ";	
					print "$h_N[$HOTCount]h","\n";
					}
					
						else
						{
						if (( $h_X[$HOTCount] <= ($midx + 5 ) && ($h_Y[$HOTCount] < ($midy + 5 ) && $h_Y[$HOTCount] > ($midy - 5 )) #GALAXY IS AT THE CENTER OF IMAGE
							  		  && $h_X[$HOTCount] >= ($midx - 5 ) && ($h_Y[$HOTCount] < ($midy + 5 ) && $h_Y[$HOTCount] > ($midy - 5 )) 
							  		  || $h_Y[$HOTCount] <= ($midy + 5 ) && ($h_X[$HOTCount] < ($midx + 5 ) && $h_X[$HOTCount] > ($midx - 5 )) 
							  		  && $h_Y[$HOTCount] >= ($midy - 5 ) && ($h_X[$HOTCount] < ($midx + 5 ) && $h_X[$HOTCount] > ($midx - 5 ))
							   			))
						{
#						print "GALAXY $h_N[$HOTCount]h\n";
						last;					
						}
#						if (sprintf("%.0f",$h_X[$HOTCount]) != sprintf("%.0f",$gX[$ColdCount]) && sprintf("%.0f",$h_Y[$HOTCount]) != sprintf("%.0f",$gY[$ColdCount]))
#						{
#							print "Crap\n" ;
#							last;
#						}							
						else
						{
							if ($h_CLASS_STAR[$HOTCount]>=0.9)
							{
							$h_kronstar = (1.5 * $h_Kron[$HOTCount]);
							print "Star inside of the kron radius $h_N[$HOTCount]\n";
							last;
							}	
						}
					}
				}
				else
				{
				print "Source outside of the kron radius $h_N[$HOTCount]h\n";
				print $HOTMASK "$h_N[$HOTCount]h,$h_X[$HOTCount],$h_Y[$HOTCount],$h_A[$HOTCount],$h_B[$HOTCount],$h_THETA[$HOTCount],$h_Kron[$HOTCount]\n";
				last;
				}
				
				
				} #close COLDAPER
			} #close HOTAPER

		}	# Close ALLAPER
	} #Close Search condition for Kron radius 
}
} #Close All

#system("/usr/bin/perl $dir/COLD_MASK1_S82.pl");
#system("/usr/bin/perl $dir/HOT_MASK1_S82.pl");
#system("/usr/bin/perl $dir/GALFIT_INPUTS_S82.pl");
#system("/usr/bin/perl $dir/Tidal_mask_S82.pl");
#print "Finished mask inputs and GALFIT inputs"
