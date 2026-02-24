#!/usr/bin/perl
use strict;
use warnings;


# CNV的vcf文件中，FORMAT格式当前只有GT，需要添加BIN和CN
my $VcfOri = $ARGV[0];
my $VcfRevise = $ARGV[1];
my $Bin4bgzip = $ARGV[2];
$Bin4bgzip = "bgzip" unless($Bin4bgzip);


open(ORI,"zcat $VcfOri |") or die $! if($VcfOri =~ /\.gz$/);
open(ORI,"cat $VcfOri |") or die $! unless($VcfOri =~ /\.gz$/);
open(REV,"| $Bin4bgzip -c > $VcfRevise") or die $! if($VcfRevise =~ /\.gz$/);
open(REV,"> $VcfRevise") or die $! unless($VcfRevise =~ /\.gz$/);
my $Flag4Format = "No";
while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		if ($Line =~ /^##FORMAT/)
		{
			$Flag4Format = "Yes";
		}
		elsif ($Flag4Format eq "Yes")
		{
			print REV "##FORMAT=<ID=DR,Number=1,Type=String,Description=\"The number of Bins\">\n";
			print REV "##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Genotype quality\">\n";
			print REV "##FORMAT=<ID=DV,Number=1,Type=String,Description=\"The copy number of CNV\">\n";
			$Flag4Format = "No";
		}
		
		print REV $Line;
		next;
	}
	
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	# BINS & CNT
	my ($BinNum, $CNT) = (".", ".");
	$BinNum = $1 if($Cols[7] =~ /BINS=([^;\t]+)/);
	$CNT = $1 if($Cols[7] =~ /LOG2CNT=([^;\t]+)/);
	$CNT = sprintf("%.2f", 2 * 2 ** $CNT) if($CNT ne ".");
	$Cols[8] = "GT:GQ:DR:DV";
	$Cols[9] = join(":",$Cols[9],".",$BinNum,$CNT);
	$Line = join("\t",@Cols);
	print REV "$Line\n";
}
close ORI;
close REV;