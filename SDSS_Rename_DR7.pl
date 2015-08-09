#! /usr/bin/perl
use strict;
use warnings;
use Text::CSV;

#This script generates:
#renaming IRAF scripts for SDSS FpC image files
#renaming shell script for PSFs
#PSF modifying script for IRAF
#wget lists for downloading PSFs

#SDSS_Positions_Size.csv can be any SDSS SQL output that contains name/name/ID, x, y, run#, field#, camcol
#Here, a generic CSV is assumed.
open my $inPositions, '<', "result_DR7.csv" or die "cannot open result_DR7.csv: $!"; 
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

#It may be necessary to change target column names. A global find/replace is best, given the large number of hardcoded entries.
my @nyuID = map {$_->{'col0'}} @{$position_inputs}; #Object ID (nyu#)
my @px = map {$_->{'imgx'}} @{$position_inputs};
my @py = map {$_->{'imgy'}} @{$position_inputs};
my @run = map {$_->{'run'}} @{$position_inputs};
my @rerun = map {$_->{'rerun'}} @{$position_inputs};
my @cam = map {$_->{'camcol'}} @{$position_inputs};
my @field = map {$_->{'field'}} @{$position_inputs};

open my $PSF_CUT, '>', "PSF_DR7.cl" or die "cannot open PSF_DR7: $!"; #PSF cutout
open my $Objects, '>', "Rename_Objects_DR7.cl" or die "cannot open Rename_Objects.cl: $!"; #IRAF
open my $PSFimages, '>', "Rename_PSF_DR7.sh" or die "cannot open Rename_PSF.sh: $!"; #Not IRAF!
open my $psflist, '>', "sdss-wget-PSF_DR7.lis" or die "cannot open sdss-wget-PSF_DR7.lis: $!"; #wget...

my $O = "fpC-";
my $DataRelease = "_DR7";
my $I = "psField";
my $J = "psf";
#my $cal ='calibPhotm';

my $run0;
my $field0;

#example wgets
#wget "http://das.sdss.org/imaging/5071/$_->{'rerun'}/objcs/1/fpAtlas-005071-1-0111.fit"
#wget "http://das.sdss.org/imaging/5071/$_->{'rerun'}/objcs/1/fpObjc-005071-1-0111.fit"
#wget "http://das.sdss.org/imaging/5071/$_->{'rerun'}/objcs/1/psField-005071-1-0111.fit"

#calibPhotom-RUN6-CAMCOL.fits
#photoObj-RUN6-CAMCOL-FIELD4.fits


my $i=0;
for (grep {$_->{'col0'}} @{$position_inputs}) { 
	local $, = ' ';
	local $\ = "\n";

	#PSF
	print $PSF_CUT "imcopy psf.$_->{'col0'}_DR7.fits[12:42,12:42] cpsf.$_->{'col0'}_DR7.fits";
	print $PSF_CUT "imarith cpsf.$_->{'col0'}_DR7.fits - 1000 scpsf.$_->{'col0'}_DR7.fits";

	my $runN = $_->{'run'};
	my $fieldN = $_->{'field'};

	#run line padding -- 6 digit field but the run number is 1 to 4 digits. (2-5 zeros of padding)
	if ($runN > 999) {
		$run0 = "00";
	} elsif ($runN > 999) {
		$run0 = "000";
	} elsif ($runN > 9) {
		$run0 = "0000";
	} else {
		$run0 = "00000";
	}

	#field line padding -- 4 digit field but the field number is 1 to 4 digits. (0-3 zeros of padding)
	if ($fieldN > 999) {
		$field0 = "";
	} elsif ($fieldN > 99) {
		$field0 = "0";
	} elsif ($fieldN > 9) {
		$field0 = "00";
	} else {
		$field0 = "000";
	}

	#Object frame
	print $Objects 'imcopy',$O..$run0.$runN.'-'.'r'.$_->{'camcol'}.'-'.$field0.$fieldN.'.fit',$_->{'col0'}.$DataRelease.'.fits';
	print 'imcopy',$O.$run0.$runN.'-'.'r'.$_->{'camcol'}.'-'.$field0.$fieldN.'.fit',$_->{'col0'}.$DataRelease.'.fits';
	
	#PSF wget list
	print $psflist "http://das.sdss.org/imaging/$runN/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-00$_->{'run'}-$_->{'camcol'}-0$_->{'field'}.fit";
	print "http://das.sdss.org/imaging/$runN/$_->{'rerun'}/objcs/$_->{'camcol'}/psField-$run0$runN-$_->{'camcol'}-$field0$fieldN.fit";

	#PSF image
	print $PSFimages 'read_PSF',$I.'-'.$run0.$runN.'-'.$_->{'camcol'}.'-'.$field0.$fieldN.'.fit','3',$_->{'imgx'},$_->{'imgy'},$J.'.'.$_->{'col0'}.$DataRelease.'.fits';
	print 'read_PSF',$I.'-'.'00'.$_->{'run'}.'-'.$_->{'camcol'}.'-'.'0'.$_->{'field'}.'.'.'fit','3',$_->{'imgx'},$_->{'imgy'},$J.'.'.$_->{'col0'}.$DataRelease.'.fits';
}	
	print "Files renamed\n";	
