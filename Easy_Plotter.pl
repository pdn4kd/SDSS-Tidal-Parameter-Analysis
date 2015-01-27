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

my @X = map{$_->{'Tc_S82'}} @{$all_data}; 
my $X = pdl(\@X);
my $min_X = min($X);
my $max_X = max($X);
my $med_X = median($X);

my @Y = map{$_->{'Tc_DR7'}} @{$all_data};
my $Y = pdl(\@Y);
my $min_Y = min($Y);
my $max_Y = max($Y);
my $med_Y = median($Y);
print "S82 $med_X, DR7 $med_Y\n";

my @R = map{$_->{'Tc_S82'} / $_->{'Tc_DR7'}} grep{$_->{'Tc_DR7'} != 0} @{$all_data};
my $R = pdl(\@R);
my $min_R = min($R);
my $max_R = max($R);
my $med_R = median($R);

my @S = map{$_->{'Tc_S82'}} grep{$_->{'Tc_DR7'} != 0} @{$all_data};
my $S = pdl(\@S);
my $min_S = min($S);
my $max_S = max($S);
#PLOTS
pgbeg(0,"Parameter_Plots.ps/vcps",1,1);
pgsci(1);pgsls(1);
pgpap(8, 1.25);pgpage;
pgsvp(0.10,0.45,0.10,0.45); #This makes a size of box
pgswin(0, 0.012, 0, 23); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',0.002,2,'bcvnst',1,1); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "Number"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "Tc"); #Bottom, x-axis
pgsch(0.75);
pgmtxt('t', 1, 0.5, 0.5, "Critical Tidal Parameters");

#All_Objects
pgsci(2);pgsch(1);
pghist(scalar @X, \@X, 0, 0.012, 6, 1);
pgsci(3);pgsch(1);
pghist(scalar @Y, \@Y, 0, 0.012, 6, 1);

#line
pgsci(2);
#pgsls(3);
pgmove($med_X,0);
pgdraw($med_X,25);

#line
pgsci(3);
pgmove($med_Y,0);
pgdraw($med_Y,25);

pgsci(1);pgsls(1);
pgsvp(0.55,0.90,0.10,0.45); #This makes a size of box
pgswin(0, $max_X*1.05, 0, $max_X*1.05); # Range of data to be plotted: (x-min, x-max, y-min, y-max);
pgslw(1);
pgsch(0.5);# text size
pgbox('bcvnst',0.002,2,'bcvnst',0.002,2); #top box
pgsls(1);pgsci(1);
pgmtxt('l', 2.5, 0.5, 0.5, "DR7 Tc"); #Left, y-axis
pgmtxt('b', 2.5, 0.5, 0.5, "Stripe 82 Tc"); #Bottom, x-axis
pgsch(0.75);
pgmtxt('t', 1, 0.5, 0.5, "Critical Tidal Parameters");

#All_Objects
pgsci(4);pgsch(1);
pgpt(scalar @X, \@X, \@Y, 1);

#line
pgsci(2);
#pgsls(3);
pgmove($med_X,0);
pgdraw($med_X,1);

#line
pgsci(3);
pgmove($med_Y,0);
pgdraw($med_Y,1);

#y=x line
pgsci(4);
pgmove(0,0);
pgdraw(0.2,0.2);
pgclos;
