perl POST_SEX_S82.pl
chmod 755 paper_all_S82.sh
./paper_all_S82.sh
perl PAPER_To_CSV.pl
perl SEG_MASK_S82.pl
perl BACKGROUND_REPLACER_S82.pl
perl GALFIT_INPUTS_S82.pl
rm galfit.*
perl Tidal_mask_S82.pl
chmod 755 GALFIT_BATCH_S82.sh
chmod 755 GALFIT_MBATCH_S82.sh
