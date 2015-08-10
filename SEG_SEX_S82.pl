use strict;
use warnings;
use Text::CSV;

# Create SExtractor input files for later segmentation mask use. 
open my $SEXtractor_parameters, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($SEXtractor_parameters));
my $parameter_inputs = $input_positions->getline_hr_all($SEXtractor_parameters);
#ID,pixel_scale,FWHM,Zero_point

my @nyuID = map {$_->{'col0'}} @{$parameter_inputs};
#my @Pixel_scale = map {$_->{'pixel_scale'}} @{$parameter_inputs};
#my @FWHM = map {$_->{'FWHM'}} @{$parameter_inputs};
my @Zp = map {$_->{'Zero_point_r'}} @{$parameter_inputs};
my @GAIN_r = map {$_->{'gain_r'}} @{$parameter_inputs};


open my $aper_all, '>', "seg_all_S82.sh" or die "cannot open seg_all_S82.sh $!";


foreach my $posCount (0 .. @nyuID - 1)
#scalar @nyuID - 1
{
	open my $SEXaper_r, '>', "p$nyuID[$posCount]_S82.seg.sex" or die "cannot open p$nyuID[$posCount].seg.sex $!";

	


print $SEXaper_r <<___end___;
#-------------------------------- Catalog ------------------------------------
 
CATALOG_NAME     p$nyuID[$posCount]_S82.seg.cat  # name of the output catalog
CATALOG_TYPE     ASCII_HEAD     # NONE,ASCII,ASCII_HEAD, ASCII_SKYCAT,
                                # ASCII_VOTABLE, FITS_1.0 or FITS_LDAC
PARAMETERS_NAME  test1.param  # name of the file containing catalog contents
 
#------------------------------- Extraction ----------------------------------
 
DETECT_TYPE      CCD            # CCD (linear) or PHOTO (with gamma correction)
DETECT_MINAREA   3              # minimum number of pixels above threshold
DETECT_THRESH    1.3             # <sigmas> or <threshold>,<ZP> in mag.arcsec-2
ANALYSIS_THRESH  1.3           # <sigmas> or <threshold>,<ZP> in mag.arcsec-2
 
FILTER           Y              # apply filter for detection (Y or N)?
FILTER_NAME      tophat_4.0_5x5.conv   # name of the file containing the filter
 
DEBLEND_NTHRESH  60            # Number of deblending sub-thresholds
DEBLEND_MINCONT  0.0003          # Minimum contrast parameter for deblending
 
CLEAN            Y              # Clean spurious detections? (Y or N)?
CLEAN_PARAM      1.0            # Cleaning efficiency
 
MASK_TYPE        CORRECT        # type of detection MASKing: can be one of
                                # NONE, BLANK or CORRECT
 
#------------------------------ Photometry -----------------------------------
 
PHOT_APERTURES   30          # MAG_APER aperture diameter(s) in pixels
PHOT_AUTOPARAMS  2.5, 3.5       # MAG_AUTO parameters: <Kron_fact>,<min_radius>
PHOT_PETROPARAMS 2.0, 3.5       # MAG_PETRO parameters: <Petrosian_fact>,
                                # <min_radius>
 
SATUR_LEVEL      55000.0        # level (in ADUs) at which arises saturation
 
MAG_ZEROPOINT    $Zp[$posCount]         # magnitude zero-point
MAG_GAMMA        4.0            # gamma of emulsion (for photographic scans)
GAIN             $GAIN_r[$posCount]           # detector gain in e-/ADU
PIXEL_SCALE      0.3961   		# size of pixel in arcsec (0=use FITS WCS info)
 
#------------------------- Star/Galaxy Separation ----------------------------
 
SEEING_FWHM      1.188          # stellar FWHM in arcsec
STARNNW_NAME     default.nnw    # Neural-Network_Weight table filename
 
#------------------------------ Background -----------------------------------
 
BACK_SIZE        64             # Background mesh: <size> or <width>,<height>
BACK_FILTERSIZE  3              # Background filter: <size> or <width>,<height>
 
BACKPHOTO_TYPE   GLOBAL         # can be GLOBAL or LOCAL
 
#------------------------------ Check Image ----------------------------------
 
CHECKIMAGE_TYPE  SEGMENTATION   # can be NONE, BACKGROUND, BACKGROUND_RMS,
                                # MINIBACKGROUND, MINIBACK_RMS, -BACKGROUND,
                                # FILTERED, OBJECTS, -OBJECTS, SEGMENTATION,
                                # or APERTURES
CHECKIMAGE_NAME  p$nyuID[$posCount]_S82.seg.fits     # Filename for the check-image
 
#--------------------- Memory (change with caution!) -------------------------
 
MEMORY_OBJSTACK  3000           # number of objects in stack
MEMORY_PIXSTACK  300000         # number of pixels in stack
MEMORY_BUFSIZE   1024           # number of lines in buffer
 
#----------------------------- Miscellaneous ---------------------------------
 
VERBOSE_TYPE     NORMAL         # can be QUIET, NORMAL or FULL
WRITE_XML        N              # Write XML file (Y/N)?
XML_NAME         sex.xml        # Filename for XML output

___end___

print $aper_all "sex p$nyuID[$posCount]_S82.fits -c p$nyuID[$posCount]_S82.seg.sex \n";
print "sex p$nyuID[$posCount]_S82.fits -c p$nyuID[$posCount]_S82.seg.sex \n";

}

print "Finished\n";
