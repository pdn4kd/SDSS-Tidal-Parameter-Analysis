use strict;
use warnings;
use PGPLOT;
use Text::CSV;
use Cwd qw(cwd);
use Statistics::OLS;
use List::Util;
use PDL;
use PDL::Graphics2D;
use PDL::Fit::Polynomial qw(fitpoly1d);
$ENV{PGPLOT_FOREGROUND} = "black";
$ENV{PGPLOT_BACKGROUND} = "white";

open my $allobj, '<', "GALFIT_Parameters_1a.csv" or die "cannot open GALFIT_Parameters_1a.csv $!"; # SDSS_STARS_SEX

#--------HASH--------
my $input_csv = Text::CSV->new({'binary'=>1});
$input_csv->column_names($input_csv->getline($allobj));
my $all_data = $input_csv->getline_hr_all($allobj);

my @X = map{$_->{'X_out'} - $_->{'X_in'}} @{$all_data}; 
my $X = pdl(\@X);
my $min_X = min($X);
my $max_X = max($X);

my @Y = map{$_->{'Y_out'}-$_->{'Y_in'}} @{$all_data};
my $Y = pdl(\@Y);
my $min_Y = min($Y);
my $max_Y = max($Y);

my @Mag = map{$_->{'Mag_out'}-$_->{'Mag_in'}} @{$all_data};
my $Mag = pdl(\@Mag);
my $min_Mag = min($Mag);
my $max_Mag = max($Mag);

my @Mag_normal = map{$_->{'Mag_in'}} @{$all_data};
my $Mag_normal = pdl(\@Mag_normal);
my $min_Mag_n = min($Mag_normal);
my $max_Mag_n = max($Mag_normal);

my @Re_Ratio = map{$_->{'Re_out'} / $_->{'Re_in'}} @{$all_data};
my $Re_Ratio = pdl(\@Re_Ratio);
my $min_Re = min($Re_Ratio);
my $max_Re = max($Re_Ratio);

my @Re = map{$_->{'Re_in'}} @{$all_data};
my $Re = pdl(\@Re);
my $min_R = min($Re);
my $max_R = max($Re);

my @PA = map{$_->{'PA_in'}} @{$all_data};
my $PA = pdl(\@PA);
my $min_PA = min($PA);
my $max_PA = max($PA);

my @dPA = map{$_->{'PA_out'}-$_->{'PA_in'}} @{$all_data};
my $dPA = pdl(\@dPA);
my $min_dPA = min($dPA);
my $max_dPA = max($dPA);

my @BA = map{$_->{'axisRatio_in'}} @{$all_data};
my $BA = pdl(\@BA);
my $min_Ba = min($BA);
my $max_Ba = max($BA);

my @dBA = map{$_->{'axisRatio_out'}-$_->{'axisRatio_in'}} @{$all_data};
my $dBA = pdl(\@dBA);
my $min_dBA = min($dBA);
my $max_dBA = max($dBA);

#open my $allobj_2, '<', "GALFIT_Galaxy_Parameters_1a.csv" or die "cannot open GALFIT_Galaxy_Parameters_1a.csv $!"; # SDSS_STARS_SEX
##--------HASH--------
#my $input_csv_2 = Text::CSV->new({'binary'=>1});
#$input_csv_2->column_names($input_csv_2->getline($allobj_2));
#my $all_data_2 = $input_csv_2->getline_hr_all($allobj_2);
#
#my @Xg = map{$_->{'X_out'} - $_->{'X_in'}} @{$all_data_2};
#my $Xg = pdl(\@Xg);
#my $min_Xg = min($Xg);
#my $max_Xg = max($Xg);
#
#my @Yg = map{$_->{'Y_out'}-$_->{'Y_in'}} @{$all_data_2};
#my $Yg = pdl(\@Yg);
#my $min_Yg = min($Yg);
#my $max_Yg = max($Yg);
#
#my @Magg = map{$_->{'Mag_out'}-$_->{'Mag_in'}} @{$all_data_2};
#my $Magg = pdl(\@Magg);
#my $min_Magg = min($Magg);
#my $max_Magg = max($Magg);
#
#my @Reg = map{$_->{'Re_in'}} @{$all_data_2};
#my $Rg = pdl(\@Reg);
#my $min_Rg = min($Rg);
#my $max_Rg = max($Rg);
#
#my @Re_Ratiog = map{$_->{'Re_out'} / $_->{'Re_in'}} @{$all_data_2};
#my $Re_Ratiog = pdl(\@Re_Ratiog);
#my $min_Reg = min($Re_Ratiog);
#my $max_Reg = max($Re_Ratiog);
#
#my @Mag_normalg = map{$_->{'Mag_in'}} @{$all_data_2};
#my $Mag_normalg = pdl(\@Mag_normalg);
#my $min_Mag_ng = min($Mag_normalg);
#my $max_Mag_ng = max($Mag_normalg);
#
#my @PAg = map{$_->{'PA_in'}} @{$all_data_2};
#my $PAg = pdl(\@PAg);
#my $min_PAg = min($PAg);
#my $max_PAg = max($PAg);
#
#my @dPAg = map{$_->{'PA_out'}-$_->{'PA_in'}} @{$all_data_2};
#my $dPAg = pdl(\@dPAg);
#my $min_dPAg = min($dPAg);
#my $max_dPAg = max($dPAg);
#
#my @BAg = map{$_->{'axisRatio_in'}} @{$all_data_2};
#my $BAg = pdl(\@BAg);
#my $min_Bag = min($BAg);
#my $max_Bag = max($BAg);
#
#my @dBAg = map{$_->{'axisRatio_out'}-$_->{'axisRatio_in'}} @{$all_data_2};
#my $dBAg = pdl(\@dBAg);
#my $min_dBAg = min($dBAg);
#my $max_dBAg = max($dBAg);
#
#my @gXg = map{$_->{'X_out'} - $_->{'X_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3) } @{$all_data_2};
#my @gYg = map{$_->{'Y_out'}-$_->{'Y_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gPAg = map{$_->{'PA_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gdPAg = map{$_->{'PA_out'}-$_->{'PA_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gBAg = map{$_->{'axisRatio_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gdBAg = map{$_->{'axisRatio_out'}-$_->{'axisRatio_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gReg = map{$_->{'Re_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gRe_Ratiog = map{$_->{'Re_out'} / $_->{'Re_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gMag_normalg = map{$_->{'Mag_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};
#my @gMagg = map{$_->{'Mag_out'}-$_->{'Mag_in'}} grep {abs($_->{'Mag_out'}-$_->{'Mag_in'}) <= 0.5 && (($_->{'Re_out'}/$_->{'Re_in'}) > 0) && (($_->{'Re_out'}/$_->{'Re_in'}) < 3)} @{$all_data_2};


#PLOTS
pgbeg(0,"Parameter_Plots.ps/vcps",1,1);
pgsci(1);pgsls(1);
pgpap(8, 1.25);pgpage;
pgsvp(0.10,0.30,0.70,0.90); #This makes a size of box
pgswin($min_X-0.1, $max_X+0.1, $min_Y-0.1,$max_Y+.1); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',1,5,'bcvnst',1,5); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "\7Y [pixels]"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "\7X [pixels]"); #Bottom, x-axis
pgsch(0.75);
#pgmtxt('t', 1, 0.5, 0.5, "\7 Background Plot");

#All_Objects
pgsci(2);pgsch(1);
pgpt(scalar @X, \@X, \@Y,2);

##GALAXIES
#pgsci(4);pgsch(1);
#pgpt(scalar @Xg, \@Xg, \@Yg,2);
#
##GALAXIES
#pgsci(11);pgsch(1);
#pgpt(scalar @gXg, \@gXg, \@gYg,4);

#Re
pgsci(1);pgsls(1);
pgsvp(0.10,0.30,0.45,0.65); #This makes a size of box
pgswin($min_R-1,$max_R+1,$min_Re-1, $max_Re+1); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',10,5,'bcvnst',1,5); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "(Galfit Re)/(SDSS Re) "); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "Re [pixels]"); #Bottom, x-axis
pgsch(0.75);
#pgmtxt('t', 1, 0.5, 0.5, "\7 Background Plot");

#All_Objects
pgsci(2);pgsch(1);
pgpt(scalar @Re, \@Re, \@Re_Ratio,2);
#
##GALAXIES Re
#pgsci(4);pgsch(1);
#pgpt(scalar @Reg, \@Reg, \@Re_Ratiog,2);
#
##gGALAXIES Re
#pgsci(11);pgsch(1);
#pgpt(scalar @gReg, \@gReg, \@gRe_Ratiog,4);

#line
pgsci(11);
pgsls(2);
pgmove(1.9,3);
pgdraw(26.9,3);

#line
pgsci(11);
pgmove(1.9,0.5);
pgdraw(26.9,0.5);

#MAg
pgsci(1);pgsls(1);
pgsvp(0.4,0.6,0.7,0.9); #This makes a size of box
#pgswin($min_Mag_n-1,$max_Mag_n+1,$min_Mag-0.1, $max_Mag+0.1); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgswin(12,24,-3,3); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',2,5,'bcvnst',1,5); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "\7(MAG)"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "V-band [Mag] "); #Bottom, x-axis
pgsch(0.75);
#pgmtxt('t', 1, 0.5, 0.5, "\7 Background Plot");

#All_MAG
pgsci(2);pgsch(1);
pgpt(scalar @Mag, \@Mag_normal, \@Mag,2);

##GALAXIES MAG
#pgsci(4);pgsch(1);
#pgpt(scalar @Magg, \@Mag_normalg, \@Magg,2);
#
##GALAXIES MAG
#pgsci(11);pgsch(1);
#pgpt(scalar @gMagg, \@gMag_normalg, \@gMagg,4);

#line
pgsci(11);
pgsls(2);
pgmove(12,0.5);
pgdraw(24,0.5);

#line
pgsci(11);
pgmove(12,-0.5);
pgdraw(24,-0.5);


#BA
pgsci(1);pgsls(1);
pgsvp(0.4,0.6,0.45,0.65); #This makes a size of box
pgswin($min_Ba-0.1,$max_Ba+0.1,$min_dBA-0.1, $max_dBA+0.1); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',0.5,5,'bcvnst',0.5,5); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "\7(b/a)"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "b/a"); #Bottom, x-axis
pgsch(0.75);
#pgmtxt('t', 1, 0.5, 0.5, "\7 Background Plot");

#All_PA
pgsci(2);pgsch(1);
pgpt(scalar @BA, \@BA, \@dBA,2);

##GALAXIES PA
#pgsci(4);pgsch(1);
#pgpt(scalar @BAg, \@BAg, \@dBAg,2);
#
##gGALAXIES PA
#pgsci(11);pgsch(1);
#pgpt(scalar @gBAg, \@gBAg, \@gdBAg,4);



#PA
pgsci(1);pgsls(1);
pgsvp(0.1,0.3,0.2,0.4); #This makes a size of box
pgswin($min_PA-1,$max_PA+1,$min_dPA-0.1, $max_dPA+0.1); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',25,5,'bcvnst',25,5); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 3.5, 0.5, 0.5, "\7(PA)"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "PA [degrees]"); #Bottom, x-axis
pgsch(0.75);
#pgmtxt('t', 1, 0.5, 0.5, "\7 Background Plot");

#All_PA
pgsci(2);pgsch(1);
pgpt(scalar @PA, \@PA, \@dPA,2);

##GALAXIES PA
#pgsci(4);pgsch(1);
#pgpt(scalar @PAg, \@PAg, \@dPAg,2);
#
##gGALAXIES PA
#pgsci(11);pgsch(1);
#pgpt(scalar @gPAg, \@gPAg, \@gdPAg,4);

##line
#pgsci(11);
#pgsls(2);
#pgmove(-90,90);
#pgdraw(90,90);
#
##line
#pgsci(11);
#pgmove(-90,-90);
#pgdraw(90,-90);

#pgsls(2);pgsci(1);
#pghist (scalar @PA, \@PA, $min_PA,$max_PA,2,3);

pgclos;