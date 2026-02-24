#!/usr/bin/perl
use strict;
use warnings;


# for sv variant split
my $File4Ori = $ARGV[0];
my $File4Flt = $ARGV[1];
my $VarType = $ARGV[2];
my $MinLen = $ARGV[3];
my $MaxLen = $ARGV[4];
my $Bin4bgzip = $ARGV[5];
$Bin4bgzip = "bgzip" unless($Bin4bgzip);
my $Bin4Tabix = $ARGV[6];
$Bin4Tabix = "tabix" unless($Bin4Tabix);

my %TypeInfo = ();
my @Types = split /,/, $VarType;
for my $i (0 .. $#Types)
{
	$TypeInfo{$Types[$i]} = "Yes";
	$TypeInfo{"TRA"} = "Yes" if($Types[$i] eq "BND");
}

open(FO,"zcat $File4Ori |") or die $! if($File4Ori =~ /\.gz$/);
open(FO,"cat $File4Ori |") or die $! if($File4Ori !~ /\.gz$/);
open(FF,"| $Bin4bgzip -c > $File4Flt") or die $! if($File4Flt =~ /\.gz$/);
open(FF,"> $File4Flt") or die $! if($File4Flt !~ /\.gz$/);
while(my $Line = <FO>)
{
	if($Line =~ /^#/)
	{
		print FF $Line;
		next;
	}
	# NanoVar can meet "SVLEN=--13" and "SVLEN=>123"
	$Line =~ s/SVLEN=--/SVLEN=-/;
	$Line =~ s/SVLEN=>/SVLEN=/;
	my @Cols = split /\t/, $Line;
	
	my $SVType = "-";
	$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
	
	# not all has SVLEN
	# pbsv/sniffles/cuteSV BND with no SVLEN
	# dysgu TRA with no SVLEN
	# debreak TRA with SVLEN=NULL
	# delly DEL/DUP/INS all may have no SVLEN, but some has
	# SVIM BND with on SVLEN ,and INV with no SVLEN
	my $SVLEN = "-";
	if($Cols[7] =~ /SVLEN=([^;]+)/)
	{
		$SVLEN = $1;
	}
	elsif($SVType eq "INV" && $Cols[3] !~ /[^ATCGN]/ && $Cols[4] !~ /[^ATCGN]/ && $Cols[3] ne "N" && $Cols[4] ne "N")
	{
		$SVLEN = length($Cols[3]);
	}
	elsif($SVType ne "BND" && $SVType ne "TRA")
	{
		if($Cols[3] !~ /[^ATCGN]/ && $Cols[4] !~ /[^ATCGN]/ && $Cols[3] ne "N" && $Cols[4] ne "N")
		{
			$SVLEN = length($Cols[4]) - length($Cols[3]);
		}
		# for delly specific
		elsif($Cols[4] eq "<DUP>" || $Cols[4] eq "<INV>" || $Cols[4] eq "<DEL>")
		{
			if($Cols[7] =~ /END=([^;]+)/)
			{
				my $RightPos = $1;
				$SVLEN = $RightPos - $Cols[1];
			}
		}
	}
	$SVLEN = "-" if($SVLEN eq "NULL");
	$SVLEN = abs($SVLEN) unless($SVLEN =~ /[^-\d]/ || $SVLEN eq "-");
	
	next unless(defined $TypeInfo{$SVType});
	next unless($TypeInfo{$SVType} eq "Yes");
	unless($SVType eq "BND" || $SVType eq "TRA")
	{
		if ($MinLen ne "-" && $SVLEN !~ /\D/)
		{
			next if($SVLEN < $MinLen);
		}
		if ($MaxLen ne "-" && $SVLEN !~ /\D/)
		{
			next if($SVLEN > $MaxLen);
		}
	}
	
	print FF $Line;
}
close FO;
close FF;

my $NumOfVar = "-";
$NumOfVar = `zcat $File4Flt | grep -v ^# | wc -l` if($File4Flt =~ /\.gz$/);
$NumOfVar = `cat $File4Flt | grep -v ^# | wc -l` if($File4Flt !~ /\.gz$/);
chomp $NumOfVar;
if($NumOfVar == 0)
{
	`rm $File4Flt`;
}
else
{
	`$Bin4Tabix -p vcf -f $File4Flt`;
}