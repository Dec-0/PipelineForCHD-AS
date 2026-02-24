#!/usr/bin/perl
use strict;
use warnings;


# for the format trans from vcf to the input of annova
my ($Vcf4Ori,$Vcf4Add,$Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);


open(ORI,"cat $Vcf4Ori |") or die $! unless($Vcf4Ori =~ /\.gz$/);
open(ORI,"zcat $Vcf4Ori |") or die $! if($Vcf4Ori =~ /\.gz$/);
open(ADD,"> $Vcf4Add") or die $! unless($Vcf4Add =~ /\.gz$/);
open(ADD,"| $Bin4bgzip -c > $Vcf4Add") or die $! if($Vcf4Add =~ /\.gz$/);

while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		print ADD $Line;
		next;
	}
	
	my @Cols = split /\t/, $Line;
	
	# if need add END;
	unless($Cols[7] =~ /[;\t]END=/)
	{
		my $SVType = "-";
		$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;\t]+)/);
		if ($SVType eq "INS")
		{
			my $End = $Cols[1] + 1;
			$Cols[7] = "END=" . $End . ";" . $Cols[7];
			$Line = join("\t", @Cols);
		}
		elsif ($SVType eq "DEL")
		{
			my $LenAlt = length($Cols[4]);
			$LenAlt = 0 if($Cols[4] eq "N" || $Cols[4] =~ /[^ATCGN]/);
			my $End = $Cols[1] + length($Cols[3]) - $LenAlt - 1;
			$Cols[7] = "END=" . $End . ";" . $Cols[7];
			$Line = join("\t", @Cols);
		}
	}
	
	print ADD $Line;
}

close ORI;
close ADD;