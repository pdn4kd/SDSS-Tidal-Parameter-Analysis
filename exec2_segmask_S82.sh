perl SEG_SEX_S82.pl
chmod 755 seg_all_S82.sh
./seg_all_S82.sh
perl SEG_To_CSV.pl
perl SEG_MASK_S82.pl
echo Run Mask_Maker_S82.cl in IRAF, then exec3
