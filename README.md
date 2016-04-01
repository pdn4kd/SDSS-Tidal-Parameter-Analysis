# SDSS-Tidal-Parameter-Analysis
Finding tidal parameters of SDSS galaxies via sérsic fits. Derived from Xia's code, which is in turn derived from [GALAPAGOS](http://astro-staff.uibk.ac.at/~m.barden/galapagos/home.html).

## Required files
tophat_4.0_5x5.conv, default.nnw, and test1.param provide additional information the scripts need to run, but you may be able to swap them out, depending on available libraries. All 3 (and other options if you're fitting galaxies from a different imaging system) should be included with a [Source Extractor](http://www.astromatic.net/software/sextractor) install.

read_PSF is also required, but not included (it's an executable). [Download/compile](http://classic.sdss.org/dr7/products/images/read_psf.html) [from SDSS](http://classic.sdss.org/dr7/products/images/read_psf.html). If you have IDL access, [SDSS has additional related utilities.](https://code.google.com/p/sdssidl/)
Perl dependencies: OpenGL Text::CSV PDL Math::Trig (semi-required: PGPlot(if debug images enabled), Cwd, Statistics, List, Astro::FITS:Header)
Additional executables: read_PSF (see above), [GALFIT](https://users.obs.carnegiescience.edu/peng/work/galfit/galfit.html), SExtractor (see above). You'll want to make them executable like system files.
3rd party software: [IRAF](http://iraf.noao.edu/) (and by extension xgterm). [SAOImage DS9](http://ds9.si.edu/site/Home.html), while not strictly required, is still useful.

## Required information/columns
col0: Some sort of ID (*PER_to_CSV.pl assume that it starts with "nyu" and will need to be modified if your scheme does not. The other files should be more agnostic)

imgx/imgy: object location within an image. (in principle findable with a reworked pipeline. Here we use known galaxies from the NYU-VAGC)

run/camcol/field: These are related to filenames within SDSS.

Zero_point_r: r-band zero-point. Query includes k-correction and airmass.

gain_r: image gain (ADU per electron) in r-band

R50_r: Initial guess of Petrosian half-light radius in r-band in pixels.

global_background_r: Sky brightness estimate. Query includes dust and airmass.

## Specific workflow:

Enter SQL query & object list
download CSV (via radio button)
download FITS images
* HTML option
* SAS/DAS
* select items (all in r-band for now)
* download foo.lis
* wget -i sdss-wget-foo.lis -P some_directory
* gunzip *gz

Rename images/download PSF
* SDSS_Rename.pl
* Rename_Atlas.cl, Rename_Objects.cl (IRAF)
* wget -i sdss-wget.lis -P some_directory
* Rename_PSF.sh
* PSF.cl (IRAF) (processes PSFs)

SExtractor I
* SDSS_SEX.pl
* aper_all.sh
* APER_to_CSV.pl

Postage Stamps
* SDSS_POSTAGE_STAMPS.pl
* Galaxy_cutout.cl (IRAF)

SExtractor II
* POST_SEX.pl
* paper_all.sh
* PAPER_to_CSV.pl
* HOT_SEX.pl
* haper_all.sh
* HAPER_to_CSV.pl

Masking/GALFIT setup (GALAPAGOS masking)
* MASTER_MASK.pl (creates CSVs that later scripts will need)
* COLD_MASK1.pl
* HOT_MAST1.pl
* BACKGROUND_REPLACER.pl
* GALFIT_INPUTS.pl
* Tidal_mask.pl (not really needed until you want to calculate Tp)
* GALFIT_BATCH.sh
Tp
* Critical_Tidal_Parameter.pl
* NOISE.cl (IRAF, must be in artdata for mknoise to work)
* GALFIT_MBATCH.sh
* Tidal_Model_Tc.pl

In general:
1. Software setup
2. Download CSV/FITS
3. Rename/download PSF
4. Postage stamps
5. SExtractor
6. Mask
7. GALFIT
8. Tidal analysis

Exact order:
0. SQL queries
1. exec0.sh
2. Rename_Atlas.cl, Rename_Objects.cl (IRAF), PSF.cl (IRAF) (processes PSFs)
3. exec1.sh
4. cutouts (in IRAF)
5. exec2_classicmask.sh
6. GALFIT_BATCH.sh
7. Critical_Tidal_Parameter.pl
8. noise.cl (in IRAF)
9. GALFIT_MBATCH.sh
10. Tidal_Model_Tc.pl

Limitations of the scripts' matching/cuts, and galfit's fitting abilities result in a leaky pipeline. Not all images will make it through to the final results. (And even fewer get through the extra data analysis steps for reasons that are unclear)

Currently an alternate route using segmentation masking also exists. Instead of step 5:
5a. exec2_segmask.sh
5b. Mask_maker.cl (in IRAF)
5c. exec3_segmask.sh

The "most advanced" alternate route is using segmentation masking with the cutout sizes and masks applied from Stripe 82 to both Stripe 82 and Data Release 7. This version also cuts out the extra renaming step, is the most heavily automated, and at present requires pulling in the files from the Tidal_Parameter_Mask repository.
1. exec01.sh
2. cutouts (PSF_Cut, Galaxy_cut) in IRAF
3. exec2_Segmask.sh (No DR7/S82 data release!)
4. Mask_Maker.cl (in IRAF)
5. exec3.sh (No data release!)
6. NOISE.cl (in IRAF)
7. exec4.sh

## Example query:
```
SELECT  
p.objID, p.ra, p.dec, p.run, p.rerun, p.camcol, p.field,dbo.fPhotoTypeN(p.type) as type, p.modelMag_g, p.modelMagErr_g, p.modelMag_r,p.modelMagErr_r, p.petroMag_g, p.petroMagErr_g,p.petroMag_r, p.petroMagErr_r, p.colc as imgx, p.rowc as imgy, (p.petroR50_r /0.3961) as R50_r, (p.petroR90_r / 0.3961) as R90_r, (p.petroR90_r/p.petroR50_r) as conc_r,f.gain_r,(-(f.aa_r + f.bb_r + f.kk_r*f.airmass_r)+4.32912) as Zero_point_r, ( power( 10,( ( ( -2.5*log10( f.skyFrames_r*power( 0.3961,2) ) ) + f.aa_r + f.kk_r * f.airmass_r) / -2.5 ) ) * 53.9 ) as global_background_r, p.isoA_g, p.isoA_r, p.isoA_i, p.isoB_g, p.isoB_r, p.isoB_i, p.isoPhi_g, p.isoPhi_r, p.isoPhi_i  
FROM #x x  
JOIN #upload u ON u.up_id = x.up_id  
JOIN PhotoObjAll p ON x.objID=p.objID  
JOIN Field f ON p.fieldID = f.fieldID  
ORDER BY x.up_id
```
for Stripe 82, add WHERE (p.run = 106 or p.run = 206) and (p.type = 3)
Note that Stripe 82's object catalog seems to have issues when compared with the general Data Release 7, so selecting a broader option (eg: All Nearby Primary Objects instead of Nearest Primary Object) may be required.

## Data Analysis:
GALFIT_OUTPUT_READER.pl and GALFIT_PARAMETERS.pl generate measures of fit quality. Run in that order to get CSVs of each cutout/fit, and then an overall listing (Del_parameters.csv).
