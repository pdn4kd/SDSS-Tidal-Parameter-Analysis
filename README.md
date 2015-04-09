# SDSS-Tidal-Parameter-Analysis
Finding tidal parameters of SDSS galaxies via sérsic fits. Derived from Xia's code.

tophat_4.0_5x5.conv, default.nnw, and test1.param provide additional information the scripts need to run, but you may be able to swap them out, depending on available libraries. read_PSF is also required, but not included. Download/compile from SDSS.

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
	
Limitations of the scripts matching/cuts, and galfits fitting abilities result in a leaky pipeline. Not all images will make it through to the final results.

Example query:
SELECT
p.objID, p.ra, p.dec, p.run, p.rerun, p.camcol, p.field,
dbo.fPhotoTypeN(p.type) as type, p.modelMag_g, p.modelMagErr_g, p.modelMag_r,p.modelMagErr_r , p.petroMag_g, p.petroMagErr_g,p.petroMag_r, p.petroMagErr_r, p.colc as imgx, p.rowc as imgy, (p.petroR50_r /0.3961) as R50_r, (p.petroR90_r / 0.3961) as R90_r, (p.petroR90_r/p.petroR50_r) as conc_r,f.gain_r,(-(f.aa_r + f.bb_r + f.kk_r*f.airmass_r)+4.32912) as Zero_point_r, ( power ( 10,( ( ( -2.5*log10 ( f.skyFrames_r*power ( 0.3961,2) ) ) + f.aa_r + f.kk_r * f.airmass_r) / -2.5 ) ) * 53.9 ) as global_background_r, p.isoA_g, p.isoA_r, p.isoA_i, p.isoB_g, p.isoB_r, p.isoB_i, p.isoPhi_g, p.isoPhi_r, p.isoPhi_i
FROM #x x
JOIN #upload u ON u.up_id = x.up_id
JOIN PhotoObjAll p ON x.objID=p.objID
JOIN Field f ON p.fieldID = f.fieldID
ORDER BY x.up_id
(for Stripe 82, add WHERE (p.run = 106 or p.run = 206) and (where p.type = 3) )
