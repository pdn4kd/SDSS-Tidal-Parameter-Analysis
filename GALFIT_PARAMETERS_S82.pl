use strict;
use warnings;
use PGPLOT;
use PDL;
use PDL::Graphics::PGPLOT;
use PDL::Graphics2D;
use PDL::Image2D;
$ENV{'PGPLOT_DIR'} = '/usr/local/pgplot';
$ENV{'PGPLOT_DEV'} = '/xs';
use Text::CSV;
use PDL::Image2D;
#use Astro::IRAF::CL;
use Cwd qw(cwd);
#use PDL::GSL::RNG;
use Cwd;
my $dir = getcwd;
 
my @galaxy_fits = qw/1 2 4 a 14/;
open my $inPositions, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};
my @Re = map {$_->{'R50_r'}} @{$position_inputs};
my @petro_mag = map {$_->{'petroMag_r'}} @{$position_inputs}; #petrosian magnitude of galaxy
my @petroErr_mag = map {$_->{'petroMagErr_r'}} @{$position_inputs}; #petrosian magnitude error
my @model_mag = map {$_->{'modelMag_r'}} @{$position_inputs};
my @modelErr_mag = map {$_->{'modelMagErr_r'}} @{$position_inputs};

open my $T_plot, '>', "Del_Parameters.csv";
print $T_plot "ID,MAG_AUTO,MAGERR_AUTO,GAL_MAG,SDSS_Re,GAL_Re,Kron,Fit_Type,sersic,GAL_x,GAL_y,SEX_x,SEX_y,SEX_e,SEX_theta,GAL_e,GAL_theta\n";

foreach my $posCount (0 .. scalar @nyuID - 1) {
foreach my $galaxy_fits (@galaxy_fits) {
if (-e "p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.csv") {
open my $file_in, '<', "p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.csv" or die "Unable to p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.csv: $!\n";	

my $input_positions_1 = Text::CSV->new({'binary'=>1});
$input_positions_1->column_names($input_positions_1->getline($file_in));
my $position_inputs_1 = $input_positions_1->getline_hr_all($file_in);

my @GAL_x = map {$_->{'x'}} @{$position_inputs_1};
my @GAL_y = map {$_->{'y'}} @{$position_inputs_1};
my @GAL_MAG = map {$_->{'Mag'}} @{$position_inputs_1};
my @GAL_Re = map {$_->{'Re'}} @{$position_inputs_1};
my @SERSIC = map {$_->{'sersicIndex'}} @{$position_inputs_1};
my @GAL_e = map {$_->{'axisRatio'}} @{$position_inputs_1};
my @GAL_theta = map {$_->{'PosAng'}} @{$position_inputs_1};

open my $file_in1, '<', "p${nyuID[$posCount]}_S82.aper.csv" or die "Unable to p${nyuID[$posCount]}_S82.aper.csv: $!\n";

my $input_positions_2 = Text::CSV->new({'binary'=>1});
$input_positions_2->column_names($input_positions_2->getline($file_in1));
my $position_inputs_2 = $input_positions_2->getline_hr_all($file_in1);

my @SEX_x = map {$_->{'X_IMAGE'}} @{$position_inputs_2};
my @SEX_y = map {$_->{'Y_IMAGE'}} @{$position_inputs_2};
my @SEX_MAG = map {$_->{'MAG_AUTO'}} @{$position_inputs_2};
my @SEX_MAGErr = map {$_->{'MAGERR_AUTO'}} @{$position_inputs_2};
my @Kron = map {$_->{'KRON_RADIUS'}} @{$position_inputs_2};

my @SEX_e = map {$_->{'ELLIPTICITY'}} @{$position_inputs_2};
my @SEX_theta = map {$_->{'THETA_IMAGE'}} @{$position_inputs_2};

		foreach my $SEXCount (0 .. scalar @SEX_x - 1)
		{	
				foreach my $gCount (0 .. scalar @GAL_x - 1)
	{	
			if (($SEX_x[$SEXCount] <= $GAL_x[$gCount] + 5) && (($SEX_y[$SEXCount] <= $GAL_y[$gCount] + 5) && ($SEX_y[$SEXCount] >= $GAL_y[$gCount] - 5))
			&& ($SEX_x[$SEXCount] >= $GAL_x[$gCount] - 5) && (($SEX_y[$SEXCount] <= $GAL_y[$gCount] + 5) && ($SEX_y[$SEXCount] >= $GAL_y[$gCount] - 5)) )
		
			{
			print $T_plot "${nyuID[$posCount]},$SEX_MAG[$SEXCount],$SEX_MAGErr[$SEXCount],$GAL_MAG[$gCount],$Re[$posCount],$GAL_Re[$gCount],$Kron[$SEXCount],$galaxy_fits,$SERSIC[$gCount],$GAL_x[$gCount],$GAL_y[$gCount],$SEX_x[$SEXCount],$SEX_y[$SEXCount],$SEX_e[$SEXCount],$SEX_theta[$SEXCount],$GAL_e[$gCount],$GAL_theta[$gCount]\n";
			}
			last;
		}
	}
	}
}
}
