#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);

my $HelpFlag;
my $ThisScriptName = basename $0;
my ($File4CNVOri,$File4CNVFlt,$Gender,$Bin4bgzip);
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script was used to filter CNV calling result by gender.

 -i      ( Required ) File for original CNV calling result;
 -o      ( Required ) File for filtered result;
 -g      ( Required ) Gender info, only support Male or Female;

 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'i=s' => \$File4CNVOri,
	'o=s' => \$File4CNVFlt,
	'g=s' => \$Gender,
	'bgz:s' => \$Bin4bgzip,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || ! $File4CNVOri || ! $File4CNVFlt || ! $Gender)
{
	die $HelpInfo;
}
else
{
	die "[ Warning ] Gender ($Gender) not correct.\n" unless($Gender eq "Male" || $Gender eq "Female");
	$Bin4bgzip = "bgzip" unless($Bin4bgzip);
}

if(1)
{
	open(ORI,"zcat $File4CNVOri |") or die $! if($File4CNVOri =~ /\.gz$/);
	open(ORI,"cat $File4CNVOri |") or die $! unless($File4CNVOri =~ /\.gz$/);
	open(FLT,"| $Bin4bgzip -c > $File4CNVFlt") or die $! if($File4CNVFlt =~ /\.gz$/);
	open(FLT,"> $File4CNVFlt") or die $! unless($File4CNVFlt =~ /\.gz$/);
	
	while(my $Line = <ORI>)
	{
		if($Line =~ /^#/)
		{
			print FLT $Line;
			next;
		}
		
		my @Cols = split /\t/, $Line;
		if($Cols[0] ne "X" && $Cols[0] ne "chrX" && $Cols[0] ne "Y" && $Cols[0] ne "chrY")
		{
			print FLT $Line;
			next;
		}
		
		if($Cols[-3] =~ /LOG2CNT=([^;\t]+)/)
		{
			my $Log2CutInfo = $1;
			
			my $Flag4Flt = 0;
			if ($Gender eq "Male")
			{
				$Flag4Flt = 1 if($Log2CutInfo <= -0.75 && $Log2CutInfo >= -1.25);
			}
			elsif ($Cols[0] eq "Y" || $Cols[0] eq "chrY")
			{
				$Flag4Flt = 1 if($Log2CutInfo < -5);
			}
			
			if ($Gender eq "Female")
			{
				$Cols[4] = "<DUP>";
				$Line = join("\t", @Cols);
			}
			
			print "[ Info ] Filter: $Line" if($Flag4Flt);
			print FLT $Line unless($Flag4Flt);
		}
		else
		{
			print "[ Info ] Could not locate LOG2CNT\n";
			print FLT $Line;
		}
	}
	
	close ORI;
	close FLT;
}
printf "[ Info ] The end.\n";


######### Sub functions ##########
