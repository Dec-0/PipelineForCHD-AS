#!/usr/bin/perl
use strict;
use warnings;


# for the format trans from vcf to the input of annova
my ($Vcf,$File4Anno,$Mode,$Other) = @ARGV;


open(ORI,"cat $Vcf | grep -v ^# |") or die $! unless($Vcf =~ /\.gz$/);
open(ORI,"zcat $Vcf | grep -v ^# |") or die $! if($Vcf =~ /\.gz$/);
open(ANN,"> $File4Anno") or die $! unless($File4Anno =~ /\.gz$/);
open(ANN,"| gzip > $File4Anno") or die $! if($File4Anno =~ /\.gz$/);
print ANN join("\t","#Chr","Start","End","Ref","Alt","SVType","FILTER","GenoType","GenoTypeQuality","NumberOfRef","NumberOfAlt"),"\n";
while(my $Line = <ORI>)
{
	chomp $Line;
	my $TransInfo = &FormatTrans($Line);
	print ANN "$TransInfo\n";
}
close ORI;
close ANN;



sub FormatTrans
{
	my $Line = $_[0];
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	my ($Chr,$Start,$End,$Ref,$Alt,$SVType,$Filter,$SVLEN,$GT,$GQ,$DR,$DV) = ("-") x 12;
	$Chr = $Cols[0];
	$Start = $Cols[1];
	$Filter = $Cols[6];
	
	if ($Mode =~ /sniffles/i)
	{
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
		$SVLEN = $1 if($Cols[7] =~ /SVLEN=([^;]+)/);
		$End = $1 if($Cols[7] =~ /END=([^;]+)/);
		
		my @SubCols = split /:/, $Cols[9];
		$GT = $SubCols[0];
		$GQ = $SubCols[1];
		$DR = $SubCols[2];
		$DV = $SubCols[3];
		
		if($SVType eq "BND")
		{
			$End = $Start + 1;
			$Alt = $Cols[4];
		}
	}
	elsif($Mode =~ /cuteSV/i)
	{
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
		$SVLEN = $1 if($Cols[7] =~ /SVLEN=([^;]+)/);
		$End = $1 if($Cols[7] =~ /END=([^;]+)/);
		
		my @SubCols = split /:/, $Cols[9];
		$GT = $SubCols[0];
		$GQ = $SubCols[4];
		$DR = $SubCols[1];
		$DV = $SubCols[2];
		
		if($SVType eq "BND")
		{
			$End = $Start + 1;
			$Alt = $Cols[4];
		}
	}
	elsif($Mode =~ /pbsv/i)
	{
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
		$SVLEN = $1 if($Cols[7] =~ /SVLEN=([^;]+)/);
		$End = $1 if($Cols[7] =~ /END=([^;]+)/);
		
		my @SubCols = split /:/, $Cols[9];
		$GT = $SubCols[0];
		my @tDP = split /,/, $SubCols[1];
		$DR = $tDP[0];
		$DV = $tDP[1];
		
		if($SVType eq "BND")
		{
			$End = $Start + 1;
			$Alt = $Cols[4];
		}
	}
	elsif($Mode =~ /debreak/i)
	{
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
		$SVLEN = $1 if($Cols[7] =~ /SVLEN=([^;]+)/);
		my $ChrPair = $1 if($Cols[7] =~ /CHR2=([^;]+)/);
		$End = $1 if($Cols[7] =~ /END=([^;]+)/);
		
		$GT = $Cols[9];
		$GQ = $1 if($Cols[7] =~ /MAPQ=([^;]+)/);
		$DV = $1 if($Cols[7] =~ /SUPPREAD=([^;]+)/);
		
		if($SVType eq "TRA")
		{
			$Alt = join(",",$ChrPair,$End);
			$End = $Start + 1;
		}
	}
	elsif($Mode =~ /nanovar/i)
	{
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
		$SVLEN = $1 if($Cols[7] =~ /SVLEN=([^;]+)/);
		$End = $1 if($Cols[7] =~ /END=([^;]+)/);
		
		my @SubCols = split /:/, $Cols[9];
		$GT = $SubCols[0];
		my @tDP = split /,/, $SubCols[2];
		$DR = $tDP[0];
		$DV = $tDP[1];
		
		if($SVType eq "BND")
		{
			$Alt = $Cols[4];
		}
	}
	else
	{
		die "[ Error ] Unknown mode ($Mode)\n"
	}
	
	return join("\t",$Chr,$Start,$End,$Ref,$Alt,$SVType,$Filter,$GT,$GQ,$DR,$DV);
}