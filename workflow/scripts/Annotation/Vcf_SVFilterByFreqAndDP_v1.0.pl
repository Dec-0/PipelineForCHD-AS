#!/usr/bin/perl
use strict;
use warnings;


# for sv variant filter
my $VcfOri = $ARGV[0];
my $VcfFlt = $ARGV[1];
my $Bin4bgzip = $ARGV[2];
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

open(ORI,"zcat $VcfOri |") or die $! if($VcfOri =~ /\.gz$/);
open(ORI,"cat $VcfOri |") or die $! unless($VcfOri =~ /\.gz$/);
open(FLT,"| $Bin4bgzip -c > $VcfFlt") or die $! if($VcfFlt =~ /\.gz$/);
open(FLT,"> $VcfFlt") or die $! unless($VcfFlt =~ /\.gz$/);
while(my $Line = <ORI>)
{
	if($Line =~ /^#/)
	{
		print FLT $Line;
		next;
	}
	
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	# Format filter
	# sniffles GT:GQ:DR:DV
	# debreak GT:DP:DR:DV
	# cuteSV GT:DR:DV:PL:GQ
	# pbsv GT:AD:DP:SAC
	my %HValue = %{&CharSplit($Cols[-2], $Cols[-1])};
	my $Flag4Flt = "No";
	if (defined $HValue{"DR"} && defined $HValue{"DV"})
	{
		if ($HValue{"DV"} ne ".")
		{
			if ($HValue{"DV"} =~ /,/)
			{
				my @DV = split /,/, $HValue{"DV"};
				my $Flag4AllMinus = "Yes";
				for my $i (0 .. $#DV)
				{
					$Flag4AllMinus = "No" if($DV[$i] >= 3);
				}
				$Flag4Flt = "Yes" if($Flag4AllMinus eq "Yes");
			}
			else
			{
				$Flag4Flt = "Yes" if($HValue{"DV"} < 3);
			}
		}
		#if ($HValue{"DV"} ne "." && $HValue{"DV"} ne ".")
		#{
		#	my $Freq = 0;
		#	$Freq = $HValue{"DV"} / ($HValue{"DR"} + $HValue{"DV"}) if($HValue{"DR"} + $HValue{"DV"} > 0);
		#	if($HValue{"DR"} + $HValue{"DV"} == 0)
		#	{
		#		print "[ 0 Warning ] $Line\n";
		#	}
		#	$Flag4Flt = "Yes" if($Freq < 0.1);
		#}
	}
	elsif (defined $HValue{"AD"} && defined $HValue{"DP"})
	{
		if ($HValue{"AD"} =~ /,/)
		{
			my @AD = split /,/, $HValue{"AD"};
			my $Flag4AllMinus = "Yes";
			for my $i (0 .. $#AD)
			{
				$Flag4AllMinus = "No" if($AD[$i] >= 3);
			}
			$Flag4Flt = "Yes" if($Flag4AllMinus eq "Yes");
		}
		else
		{
			$Flag4Flt = "Yes" if($HValue{"AD"} < 3);
		}
		#my $Freq = 0;
		#$Freq = $HValue{"AD"} / $HValue{"DP"} if($HValue{"DP"} > 0);
		#if($HValue{"DP"} == 0)
		#{
		#	print "[ 0 Warning ] $Line\n";
		#}
		#$Flag4Flt = "Yes" if($Freq < 0.1);
	}
	else
	{
		print "[ Info ] Unknown format $Cols[-2]\n";
	}
	
	if($Flag4Flt eq "Yes")
	{
		#print "[ Flt ] $Cols[7] $Cols[8] $Cols[9]\n";
		next;
	}
	print FLT $Line,"\n";
}
close ORI;
close FLT;


#------------
sub CharSplit
{
	my ($Str4Format, $Str4Value) = @_;
	
	my @Items = split /:/, $Str4Format;
	my @Values = split /:/, $Str4Value;
	
	my %HValue = ();
	for my $i (0 .. $#Items)
	{
		$HValue{$Items[$i]} = $Values[$i];
	}
	
	return \%HValue;
}