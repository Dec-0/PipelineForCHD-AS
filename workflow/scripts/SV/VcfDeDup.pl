#!/usr/bin/perl
use strict;
use warnings;


# for the format trans from vcf to the input of annova
my ($Vcf,$VcfDeDup,$Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

my %DupInfo = ();
open(ORI,"cat $Vcf |") or die $! unless($Vcf =~ /\.gz$/);
open(ORI,"zcat $Vcf |") or die $! if($Vcf =~ /\.gz$/);
open(DEDUP,"> $VcfDeDup") or die $! unless($VcfDeDup =~ /\.gz$/);
open(DEDUP,"| $Bin4bgzip -c > $VcfDeDup") or die $! if($VcfDeDup =~ /\.gz$/);
while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		print DEDUP $Line;
		next;
	}
	my @Cols = split /\t/, $Line;
	my $Key = join("\t",@Cols[0 .. 4]);
	if(defined $DupInfo{$Key})
	{
		next if($DupInfo{$Key} eq "Yes");
	}
	$DupInfo{$Key} = "Yes";
	
	print DEDUP $Line;
}
close ORI;
close DEDUP;