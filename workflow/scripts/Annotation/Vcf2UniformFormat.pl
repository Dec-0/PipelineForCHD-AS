#!/usr/bin/perl
use strict;
use warnings;


# 用于统一sniffles、debreak、pbsv vcf FORMAT列的格式输出，便于jasmine合并操作
## debreak
# 1 3428201 db103   N       <DUP>   .       PASS    SVMETHOD=DeBreak_1.0;CHR2=1;END=3428332;SVTYPE=DUP;SVLEN=131;SUPPREAD=19;MAPQ=60.0                      GT      0/1
# 1 3477295 db21149 N       <TRA>   .       PASS    IMPRECISE;SVMETHOD=DeBreak_1.0;CHR2=15;END=79437741;SVTYPE=TRA;SVLEN=NULL;SUPPREAD=8;MAPQ=40.875        GT      0/1
# 1 1245150 db29    N       <INS>   .       PASS    SVMETHOD=DeBreak_1.0;CHR2=1;END=1245151;SVTYPE=INS;SVLEN=442;SUPPREAD=35;MAPQ=60.0                      GT      1/1
## pbsv
# 1 1068755 pbsv.INS.DUP.37                 G       <DUP>           .       PASS    SVTYPE=DUP;END=1068809;SVLEN=54                                 GT:AD:DP:SAC    1/1:2,53:55:1,1,29,24
# 1 883219  pbsv.BND.1:883219-20:29351293   C       C]20:29351293]  .       PASS    SVTYPE=BND;CIPOS=-28,25;MATEID=pbsv.BND.20:29351293-1:883219    GT:AD:DP        0/1:63,11:74
# 1 1749605 pbsv.INS.69                     C       CGTCCA..GGT     .       PASS    SVTYPE=INS;END=1749605;SVLEN=50                                 GT:AD:DP:SAC    1/1:0,44:44:0,0,16,28
## sniffles
# 1 2325197  Sniffles2.BND.73AFS0 N  N]X:2227389]  60  PASS    IMPRECISE;SVTYPE=BND;SUPPORT=12;COVERAGE=34,0,30,31,33;STRAND=+-;AF=0.400;CHR2=X;STDEV_POS=44.403                                                       GT:GQ:DR:DV     0/1:60:18:12
# 1 1382737  Sniffles2.INS.5DS0   N  CACCAC..GGC   60  PASS    IMPRECISE;SVTYPE=INS;SVLEN=145;END=1382737;SUPPORT=13;COVERAGE=50,56,57,57,58;STRAND=+-;AF=0.228;STDEV_LEN=18.866;STDEV_POS=47.584;SUPPORT_LONG=0       GT:GQ:DR:DV     0/1:7:44:13
# 1 18049229 Sniffles2.DUP.4C13S0 N  <DUP>         54  PASS    PRECISE;SVTYPE=DUP;SVLEN=773;END=18050002;SUPPORT=16;COVERAGE=53,53,73,48,46;STRAND=+-;AF=0.258;STDEV_LEN=4.406;STDEV_POS=4.166                         GT:GQ:DR:DV     0/1:31:46:16

my ($VcfOri,$VcfUniform,$Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

open(ORI,"zcat $VcfOri |") or die $! if($VcfOri =~ /\.gz$/);
open(ORI,"cat $VcfOri |") or die $! unless($VcfOri =~ /\.gz$/);
open(UNIF,"| $Bin4bgzip -c > $VcfUniform") or die $! if($VcfUniform =~ /\.gz$/);
open(UNIF,"> $VcfUniform") or die $! unless($VcfUniform =~ /\.gz$/);
while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		print UNIF $Line;
		next;
	}
	my $NLine = &FormatUniform($Line);
	print UNIF $NLine;
}
close ORI;
close UNIF;


sub FormatUniform
{
	my $Line = $_[0];
	
	chomp $Line;
	my @Cols = split /\t/, $Line;
	my @Items = split /:/, $Cols[8];
	my @Values = split /:/, $Cols[9];
	my %IVHash = ();
	for my $i (0 .. $#Items)
	{
		$IVHash{$Items[$i]} = $Values[$i];
	}
	
	# GT:GQ:DR:DV or GT:AD:DP or GT:AD:DP:SAC or GT:DP:DR:DV
	my ($GT,$GQ,$DR,$DV) = ("." ,"." ,"." ,".");
	$GT = $IVHash{"GT"} if(defined $IVHash{"GT"});
	
	if(defined $IVHash{"GQ"})
	{
		$GQ = $IVHash{"GQ"};
	}
	else
	{
		$GQ = $1 if($Cols[7] =~ /MAPQ=([^;]+)/);
		$GQ = int($GQ) unless($GQ =~ /[^\d]/);
	}
	
	if(defined $IVHash{"DR"})
	{
		$DR = $IVHash{"DR"};
	}
	elsif(defined $IVHash{"AD"})
	{
		my ($Ref,$Alt) = split /,/, $IVHash{"AD"};
		$DR = $Ref;
	}
	
	if(defined $IVHash{"DV"})
	{
		$DV = $IVHash{"DV"};
	}
	elsif(defined $IVHash{"AD"})
	{
		my ($Ref,$Alt) = split /,/, $IVHash{"AD"};
		$DV = $Alt;
	}
	else
	{
		$DV = $1 if($Cols[7] =~ /SUPPREAD=([^;]+)/);
	}
	
	$Cols[8] = "GT:GQ:DR:DV";
	$Cols[9] = join(":",$GT,$GQ,$DR,$DV);
	$Line = join("\t",@Cols) . "\n";
	
	return $Line;
}