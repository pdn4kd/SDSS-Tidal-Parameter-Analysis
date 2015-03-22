perl SDSS_Rename_S82.pl
wget -i sdss-wget-PSF_S82.lis
wget -i sdss-wget-Calibration_S82.lis
chmod 755 Rename_PSF_S82.sh
./Rename_PSF_S82.sh
