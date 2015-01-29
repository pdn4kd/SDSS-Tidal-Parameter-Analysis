# SDSS-Tidal-Parameter-Analysis
Finding tidal parameters of SDSS galaxies via sérsic fits. Derived from Xia's code.

Specific workflow:

Enter SQL query & object list
download CSV (via radio button)
download FITS images
	HTML option
	SAS/DAS
	select items (all in r-band for now)
	download foo.lis
	wget -i sdss-wget-foo.lis -P some_directory
	gunzip *gz
Rename images/download PSF
	SDSS_Rename.pl
	Rename_Atlas.cl, Rename_Objects.cl (IRAF)
	wget -i sdss-wget.lis -P some_directory
	Rename_PSF.sh
	PSF.cl (IRAF) (processes PSFs)
SExtractor I
	SDSS_SEX.pl
	aper_all.sh
	APER_to_CSV.pl
Postage Stamps
	SDSS_POSTAGE_STAMPS.pl
	Galaxy_cutout.cl (IRAF)
SExtractor II
	POST_SEX.pl
	paper_all.sh
	PAPER_to_CSV.pl
	HOT_SEX.pl
	haper_all.sh
	HAPER_to_CSV.pl
Masking/GALFIT setup
	MASTER_MASK.pl (runs cold/hot/tidal/Galfit_inputs.pl)
	GALFIT_BATCH.sh
Tp
	Critical_Tidal_Parameter.pl
	NOISE.cl (IRAF)
	GALFIT_MBATCH.sh
	Tidal_Model_Tc.pl

In general:
	1) Software setup
	2) Download CSV/FITS
	3) Rename/download PSF
	4) Postage stamps
	5) SExtractor
	6) Mask
	7) GALFIT
	8) Tidal analysis
	
Exact order:
	0) SQL queries
	1) exec0.sh
	2) Rename_Atlas.cl, Rename_Objects.cl (IRAF), PSF.cl (IRAF) (processes PSFs)
	3) exec1.sh
	4) cutouts in IRAF
	5) exec2.sh
	6) GALFIT_BATCH.sh
	7) Critical_Tidal_Parameter.pl
	8) noise.cl (IRAF)
	9) GALFIT_MBATCH.sh
	10) Tidal_Model_Tc.pl

Not scripts, but needed by them and associated software (IRAF, GALFIT, SExtractor)
	default.nnw
	test.param
	tophat_40_5x5.conv
	read_PSF
