#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);

my ($File4Ori, $Vcf, $Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

if(1)
{
my $VcfHeader = <<VCFHEAD;
##fileformat=VCFv4.2
##source=ExomeDepth
##REF=<ID=DIP,Description="CNV call">
##ALT=<ID=DEL,Description="Deletion">
##ALT=<ID=DUP,Description="Duplication">
##FILTER=<ID=LOWQ,Description="Filtered due to call in low quality region">
##INFO=<ID=SVTYPE,Number=1,Type=String,Description="Type of variant: DEL,DUP,INS">
##INFO=<ID=SVLEN,Number=1,Type=Integer,Description="Length of variant">
##INFO=<ID=BINS,Number=1,Type=Integer,Description="Number of bins in call">
##INFO=<ID=SCORE,Number=1,Type=Integer,Description="Score of calling algorithm">
##INFO=<ID=LOG2CNT,Number=1,Type=Float,Description="Log 2 count">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	Sample
VCFHEAD
	
	
	open(ORI,"zcat $File4Ori | grep -v ^# |") or die $! if($File4Ori =~ /\.gz$/);
	open(ORI,"cat $File4Ori | grep -v ^# |") or die $! unless($File4Ori =~ /\.gz$/);
	open(REV,"| $Bin4bgzip -c > $Vcf") or die $! if($Vcf =~ /\.gz$/);
	open(REV,"> $Vcf") or die $! unless($Vcf =~ /\.gz$/);
	
	print REV $VcfHeader;
	
	while(my $Line = <ORI>)
	{
		chomp $Line;
		next if(length($Line) == 0);
		my @Cols = split /\t/, $Line;
		next if($Cols[0] eq "start.p");
		
		my $Chr = $Cols[6];
		my $Pos = $Cols[4];
		my $ID = ".";
		my $Ref = "<DIP>";
		my $SVType = "DUP";
		$SVType = "DEL" if($Cols[2] eq "deletion");
		my $Alt = "<DUP>";
		$Alt = "<DEL>" if($Cols[2] eq "deletion");
		my $Qual = "1000";
		my $Filter = "PASS";
		my $SVLen = $Cols[5] - $Cols[4];
		my $CN = $Cols[11];
		my $LogCN = "-1000";
		$LogCN = sprintf("%.2f", log($CN) / log(2)) if($CN > 0);
		my $Info = "SVTYPE=" . $SVType . ";END=" . $Cols[5] . ";SVLEN=" . $SVLen . ";BINS=" . $Cols[3] . ";SCORE=-1;LOG2CNT=" . $LogCN;
		my $Format = "GT";
		my $Value = "0/1";
		$Value = "1/1" if($CN < 0.5 || $CN > 1.5);;
		
		print REV join("\t",$Chr,$Pos,$ID,$Ref,$Alt,$Qual,$Filter,$Info,$Format,$Value),"\n";
	}
	
	close ORI;
	close REV;
}
printf "[ Info ] The end.\n";


######### Sub functions ##########
