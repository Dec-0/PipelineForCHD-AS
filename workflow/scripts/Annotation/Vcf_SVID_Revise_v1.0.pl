#!/usr/bin/perl
use strict;
use warnings;


my ($VcfOri,$VcfRevise,$Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

open(ORI,"zcat $VcfOri |") or die $! if($VcfOri =~ /\.gz$/);
open(ORI,"cat $VcfOri |") or die $! unless($VcfOri =~ /\.gz$/);
open(REV,"| $Bin4bgzip -c > $VcfRevise") or die $! if($VcfRevise =~ /\.gz$/);
open(REV,"> $VcfRevise") or die $! unless($VcfRevise =~ /\.gz$/);
while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		print REV $Line;
		next;
	}
	
	my @Cols = split /\t/, $Line;
	if($Cols[2] =~ /pbsv.BND/)
	{
		$Cols[2] =~ s/:/_/g;
		$Cols[2] =~ s/-/_/g;
		$Line = join("\t",@Cols);
	}
	print REV $Line;
}
close ORI;
close REV;