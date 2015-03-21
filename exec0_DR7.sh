perl SDSS_Rename_DR7.pl
wget -i sdss-wget-PSF_DR7.lis
wget -i sdss-wget-Calibration_DR7.lis
chmod 755 Rename_PSF_DR7.sh
./Rename_PSF_DR7.sh
