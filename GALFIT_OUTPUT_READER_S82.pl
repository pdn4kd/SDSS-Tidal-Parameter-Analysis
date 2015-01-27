use strict;
use warnings;
use PDL;
use Text::CSV;

my @galaxy_fits = qw/1 2 4 a 14/;

open my $inPositions, '<', "result_S82.csv" or die "cannot open result_S82.csv: $!";
my $input_positions = Text::CSV->new({'binary'=>1});
$input_positions->column_names($input_positions->getline($inPositions));
my $position_inputs = $input_positions->getline_hr_all($inPositions);

my @nyuID = map {$_->{'col0'}} @{$position_inputs};

foreach my $posCount (0 .. scalar @nyuID - 1) {
foreach my $galaxy_fits (@galaxy_fits) {
my $file = "p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.out";
if (-e "$file") { 
open my $fdIn, '<', $file  or die "Unable to open $file: $!\n";
open my $fdOut, '>', "p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.csv" or die "Unable to p${nyuID[$posCount]}_S82.galfit_$galaxy_fits.csv: $!\n";

print $fdOut "type,x,y,posFlag1,posFlag2,Mag,mag_Flag,Re,Re_Flag,sersicIndex,seric_Flag,axisRatio,ar_Flag,PosAng,pa_Flag,skipImage_Flag,Fit_Type\n";
while(1) {
     # skip all lines until you reach the component listing
     while(defined($_ = <$fdIn>) && $_ !~ /^# Component number:/){}

     last if eof $fdIn;

     <$fdIn> =~ /\)\s+?(\w+)\s+#/;
     my $type = $1;
     if($type eq 'sersic') {
         &readSersicFit($fdIn,$fdOut);
     } elsif ($type eq 'expdisk') {
         &readDiskFit($fdIn,$fdOut);
     } elsif ($type eq 'psf') {
         &psf($fdIn,$fdOut);
     } elsif ($type eq 'sky') {
         &readSkyFit($fdIn,$fdOut);
     } else {
         print "Unknown component type: $type\n";
     }

     last if eof $fdIn;
}
}
sub readDiskFit(){
my ($fdIn,$fdOut) = @_;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($ra,$dec,$posFlag1,$posFlag2) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($integratedMag, $imFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($Re, $reFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($sersicIndex,$siFlag) = split(' ', $1);

     # skip the next three lines
     <$fdIn>;<$fdIn>;<$fdIn>;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($axisRatio,$arFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($posAng,$paFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($skipImageFlag) = split(' ', $1);

     print $fdOut
join(',','expdisk',$ra,$dec,$posFlag1,$posFlag2,$integratedMag,$imFlag,$Re,$reFlag,$sersicIndex,$siFlag,$axisRatio,$arFlag,$posAng,$paFlag,$skipImageFlag),"\n";
}

sub psf(){
     my ($fdIn,$fdOut) = @_;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($ra,$dec,$posFlag1,$posFlag2) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($integratedMag, $imFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($Re, $reFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($sersicIndex,$siFlag) = split(' ', $1);

     # skip the next three lines
     <$fdIn>;<$fdIn>;<$fdIn>;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($axisRatio,$arFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($posAng,$paFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($skipImageFlag) = split(' ', $1);

     print $fdOut join(',','psf',$ra,$dec,$posFlag1,$posFlag2,$integratedMag,$imFlag,$Re,$reFlag,$sersicIndex,$siFlag,$axisRatio,$arFlag,$posAng,$paFlag,$skipImageFlag),"\n";
}

sub readSkyFit(){
     my ($fdIn,$fdOut) = @_;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($bg,$bgFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($dSkyX, $dSkyXflag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($dSkyY, $dSkyYflag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($skipImageFlag) = split(' ', $1);

#     print $fdOut join(',',
#'sky',$bg,$bgFlag,$dSkyX,$dSkyXflag,$dSkyY,$dSkyYflag,$skipImageFlag), "\n";
#
#}
     print $fdOut join(',','sky',$dSkyX,$dSkyY,$dSkyXflag,$dSkyYflag,$bg,$bgFlag,'0','0','0','0','0','0','0','0',$skipImageFlag),"\n";
}

#type,ra,dec,posFlag1,posFlag2,Mag,mag_Flag,Re,Re_Flag,sersicIndex,seric_Flag,axisRatio,ar_Flag,PosAng,pa_Flag,skipImage_Flag

sub readSersicFit(){
     my ($fdIn,$fdOut) = @_;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($ra,$dec,$posFlag1,$posFlag2) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($integratedMag, $imFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($Re, $reFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($sersicIndex,$siFlag) = split(' ', $1);

     # skip the next three lines
     <$fdIn>;<$fdIn>;<$fdIn>;

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($axisRatio,$arFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($posAng,$paFlag) = split(' ', $1);

     <$fdIn> =~ /\)\s+(.*)#/;
     my ($skipImageFlag) = split(' ', $1);

     print $fdOut join(',','sersic',$ra,$dec,$posFlag1,$posFlag2,$integratedMag,$imFlag,$Re,$reFlag,$sersicIndex,$siFlag,$axisRatio,$arFlag,$posAng,$paFlag,$skipImageFlag),"\n";
}
}
}
