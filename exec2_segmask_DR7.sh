perl POST_SEX_DR7.pl
chmod 755 paper_all_DR7.sh
./paper_all_DR7.sh
perl PAPER_To_CSV.pl
perl SEG_MASK_DR7.pl
perl BACKGROUND_REPLACER_DR7.pl
perl GALFIT_INPUTS_DR7.pl
rm galfit.*
perl Tidal_mask_DR7.pl
chmod 755 GALFIT_BATCH_DR7.sh
chmod 755 GALFIT_MBATCH_DR7.sh
