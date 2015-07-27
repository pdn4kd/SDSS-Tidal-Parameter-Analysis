use strict;
use warnings;
#use PGPLOT;
use Text::CSV;
use Cwd qw(cwd);
#use String::Scanf;
#use Statistics::OLS;
use PDL;
#use PDL::Graphics2D;
#use PDL::Fit::Polynomial qw(fitpoly1d);
#$ENV{PGPLOT_FOREGROUND} = "black";
#$ENV{PGPLOT_BACKGROUND} = "white";
#use Cwd;
#my $dir = getcwd;
 
 my @galaxy_fits = qw/1 2 4 a 14/; #model fits we are checking
 
#MASK_INPUT.csv will need to be changed on a per-image basis (at the moment?)
open my $inGalPositions, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!"; #Change the input to your input file with the galaxy coordinates
my $positions = Text::CSV->new({'binary'=>1});
$positions->column_names($positions->getline($inGalPositions));
my $position = $positions->getline_hr_all($inGalPositions);

my @nyuID = map {$_->{'col0'}} @{$position};
my @ZPR = map {$_->{'Zero_point_r'}} @{$position};
my @bkg = map {$_->{'global_background_r'}+1000} @{$position};

	
open my $galfit_batch, '>', "GALFIT_BATCH_S82.sh" or die "cannot open GALFIT_BATCH_S82.sh: $!";
open my $mgalfit_batch, '>', "GALFIT_MBATCH_S82.sh" or die "cannot open GALFIT_BATCH_S82.sh: $!";
#system("/usr/bin/perl $dir/BACKGROUND_REPLACER_S82.pl");
foreach my $galCount (0 .. scalar @nyuID - 1) {
if (-e "p${nyuID[$galCount]}_S82.fits") {
my $Good_values = rfits("background.p$nyuID[$galCount]_S82.fits");
my $average = sprintf("%.3f",(avg($Good_values)));
print $average,"\n";
	
print "background.p${nyuID[$galCount]}_S82.fits\n";	
open my $inPositions, '<', "p$nyuID[$galCount]_S82.galfit_input.csv" or die "cannot open p$nyuID[$galCount]_S82.galfit_input.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

foreach my $galaxy_fits (@galaxy_fits) { #iterate over all fit types
	print $galfit_batch "galfit p$nyuID[$galCount]_S82.galfit_$galaxy_fits\n";
	print $galfit_batch "mv galfit.01 p$nyuID[$galCount]_S82.galfit_$galaxy_fits.out\n";
	print $mgalfit_batch "galfit mp$nyuID[$galCount]_S82.galfit_$galaxy_fits\n";
	print $mgalfit_batch "mv galfit.01 mp$nyuID[$galCount]_S82.galfit_$galaxy_fits.out\n";
	}

my @N = map {$_->{'NUMBER'}} @{$position_inputs}; #mag
my @mag = map {$_->{'MAG'}} @{$position_inputs}; #mag
my @Re = map {$_->{'Re'}} @{$position_inputs}; #RE
my @px = map {$_->{'X'}} @{$position_inputs}; 
my @py = map {$_->{'Y'}} @{$position_inputs};
my @X = map {$_->{'sizex'}} @{$position_inputs};
my @Y = map {$_->{'sizey'}} @{$position_inputs};
my @THETA_IMAGE = map {$_->{'THETA'}} @{$position_inputs};
my @ba = map {$_->{'ba'}} @{$position_inputs};
my @fit = map {$_->{'fit'}} @{$position_inputs};
my @type = map {$_->{'type'}} @{$position_inputs};

foreach my $posCount (0 .. scalar @N - 1)
{
	open my $galfit1, '>', "p$nyuID[$galCount]_S82.galfit_1" or die "cannot open p$nyuID[$galCount]_S82.galfit_1 $!"; #GALFIT Normal Galaxy (n=1)
	open my $mgalfit1, '>', "mp$nyuID[$galCount]_S82.galfit_1" or die "cannot open mp$nyuID[$galCount]_S82.galfit_1 $!"; #GALFIT Normal Galaxy model (n=1)

	open my $galfit2, '>', "p$nyuID[$galCount]_S82.galfit_2" or die "cannot open p$nyuID[$galCount]_S82.galfit_2 $!"; #GALFIT Normal Galaxy (n=2)
	open my $mgalfit2, '>', "mp$nyuID[$galCount]_S82.galfit_2" or die "cannot open mp$nyuID[$galCount]_S82.galfit_2 $!"; #GALFIT Normal Galaxy model (n=2)
	open my $galfit4, '>', "p$nyuID[$galCount]_S82.galfit_4" or die "cannot open p$nyuID[$galCount]_S82.galfit_4 $!"; #GALFIT Normal Galaxy (n=4)
	open my $mgalfit4, '>', "mp$nyuID[$galCount]_S82.galfit_4" or die "cannot open mp$nyuID[$galCount]_S82.galfit_4 $!"; #GALFIT Normal Galaxy model (n=4)
	open my $galfita, '>', "p$nyuID[$galCount]_S82.galfit_a" or die "cannot open p$nyuID[$galCount]_S82.galfit_a $!"; #GALFIT Normal Galaxy (n=anything)
	open my $mgalfita, '>', "mp$nyuID[$galCount]_S82.galfit_a" or die "cannot open mp$nyuID[$galCount]_S82.galfit_a $!"; #GALFIT Normal Galaxy model (n=anything)

	open my $galfit14, '>', "p$nyuID[$galCount]_S82.galfit_14" or die "cannot open p$nyuID[$galCount]_S82.galfit_14 $!"; #GALFIT 2 component Normal Galaxy (n=1 disk, n=4 bulge)
	open my $mgalfit14, '>', "mp$nyuID[$galCount]_S82.galfit_14" or die "cannot open mp$nyuID[$galCount]_S82.galfit_14 $!"; #GALFIT 2 component Normal Galaxy model (n=1 disk, n=4 bulge)

print $galfit1  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_S82.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_S82.model_1.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $mgalfit1  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) bmodel.p$nyuID[$galCount]_S82_1.fits      # Input data image (FITS file)
B) mp$nyuID[$galCount]_S82.model_1.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


print $galfit2  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_S82.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_S82.model_2.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $mgalfit2  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) bmodel.p$nyuID[$galCount]_S82_2.fits      # Input data image (FITS file)
B) mp$nyuID[$galCount]_S82.model_2.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


print $galfit4  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_S82.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_S82.model_4.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $mgalfit4  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) bmodel.p$nyuID[$galCount]_S82_4.fits      # Input data image (FITS file)
B) mp$nyuID[$galCount]_S82.model_4.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $galfita  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_S82.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_S82.model_a.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $mgalfita  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) bmodel.p$nyuID[$galCount]_S82_a.fits      # Input data image (FITS file)
B) mp$nyuID[$galCount]_S82.model_a.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


print $galfit14  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) MASKED.p$nyuID[$galCount]_S82.fits      # Input data image (FITS file)
B) p$nyuID[$galCount]_S82.model_14.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___

print $mgalfit14  <<___end___;
================================================================================
# IMAGE and GALFIT CONTROL PARAMETERS
A) bmodel.p$nyuID[$galCount]_S82_14.fits      # Input data image (FITS file)
B) mp$nyuID[$galCount]_S82.model_14.fits      # Output data image block
C) #                   # Sigma image name (made from data if blank or "none") 
D) scpsf.$nyuID[$galCount]_S82.fits           # Input PSF image and (optional) diffusion kernel
E) 1                  # PSF fine sampling factor relative to data 
F) FMASK.p$nyuID[$galCount]_S82.fits      # Bad pixel mask (FITS image or ASCII coord list)
G) none                # File with parameter constraints (ASCII file) 
H) 1 $X[$posCount]  1 $Y[$posCount]       # Image region to fit (xmin xmax ymin ymax)
I) 100 100           # Size of the convolution box (x y)
J) $ZPR[$galCount]          # Magnitude photometric zeropoint 
K) 0.3961 0.3961       # Plate scale (dx dy)   [arcsec per pixel]
O) regular             # Display type (regular, curses, both)
P) 0                   # Choose: 0=optimize, 1=model, 2=imgblock, 3=subcomps

# INITIAL FITTING PARAMETERS
#
#   For component type, the allowed functions are: 
#       sersic, expdisk, edgedisk, devauc, king, nuker, psf, 
#       gaussian, moffat, ferrer, and sky. 
#  
#   Hidden parameters will only appear when they're specified:
#       Bn (n=integer, Bending Modes).
#       C0 (diskyness/boxyness), 
#       Fn (n=integer, Azimuthal Fourier Modes).
#       R0-R10 (coordinate rotation, for creating spiral structures).
#       To, Ti, T0-T10 (truncation function).
# 
# ------------------------------------------------------------------------------
#   par)    par value(s)    fit toggle(s)    # parameter description 
# ------------------------------------------------------------------------------
___end___


foreach my $posCount (0 .. scalar @N - 1)
{
print $galfit1  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $mgalfit1  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $galfit2  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $mgalfit2  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $galfit4  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $mgalfit4  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $galfita  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.5000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___

print $mgalfita  <<___end___;
# Component number: $N[$posCount]
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 2.5000      1          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)

___end___


print $galfit14  <<___end___;
# Component number: $N[$posCount], exp fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $galfit14  <<___end___;
# Component number: $N[$posCount], de Vaucouleurs fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $mgalfit14  <<___end___;
# Component number: $N[$posCount], exp fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 1.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

print $mgalfit14  <<___end___;
# Component number: $N[$posCount], de Vaucouleurs fit
 0) $type[$posCount]         #  Component type
 1) $px[$posCount] $py[$posCount] 1 1  #  Position x, y
 3) $mag[$posCount]  1          #  Integrated magnitude 
 4) $Re[$posCount]   1         #  R_e (effective radius)   [pix]
 5) 4.0000      0          #  Sersic index n (de Vaucouleurs n=4) 
 6) 0.0000      0          #     ----- 
 7) 0.0000      0          #     ----- 
 8) 0.0000      0          #     ----- 
 9) $ba[$posCount]   1          #  Axis ratio (b/a)  
10) $THETA_IMAGE[$posCount]    1          #  Position angle (PA) [deg: Up=0, Left=90]
 Z) 0                       #  Skip this model in output image?  (yes=1, no=0)
___end___

}
print $galfit1 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $mgalfit1 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $galfit2 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $mgalfit2 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $galfit4 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $mgalfit4 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $galfita <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___

print $mgalfita <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================

___end___


print $galfit14 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================
___end___

print $mgalfit14 <<___end___;
# Component number: Sky
 0) sky                    #  Component type
 1) $average        0          #  Sky background at center of fitting region [ADUs]
 2) 0		    	0       #  dsky/dx (sky gradient in x)     [ADUs/pix]
 3) 0		    	0       #  dsky/dy (sky gradient in y)     [ADUs/pix]
 Z) 0                      #  Skip this model in output image?  (yes=1, no=0)
================================================================================
___end___
}
}
#system ("rm $dir/galfit.* ");
#system ("/usr/local/bin/galfit $dir/p$nyuID[$galCount]_S82.galfit_1");
#system ("mv galfit.01 $dir/");
#print "Finished p$nyuID[$galCount].fits\n";	

}

print "Done";
