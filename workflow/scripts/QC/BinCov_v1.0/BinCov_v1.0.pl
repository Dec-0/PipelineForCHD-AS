#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/.Modules";
use Parameter::BinList;

my ($HelpFlag,$BinList,$BeginTime);
my ($File4Bam,$File4Bed,$File4Log,$Mode4Seq,$Bed4Genome);
my $ThisScriptName = basename $0;
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script was used to calculate Read Count and Mean Depth of bed area.

 -bam    ( Required ) Bam file;
 -bed    ( Required ) Panel bed file;
 -log    ( Required ) File for logging;

 -mode   ( Optional ) Mode for bam, ONT or NGS (default: ONT);
 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'bam=s' => \$File4Bam,
	'bed=s' => \$File4Bed,
	'log=s' => \$File4Log,
	'mode:s' => \$Mode4Seq,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || ! $File4Bam || ! $File4Bed || ! $File4Log)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	
	$BinList = BinListGet() if(!$BinList);
	#$Bed4Genome = BinSearch("Bed4Genome",$BinList);
	IfFileExist($File4Bam,$File4Bed);
	my $tDir = dirname $File4Log;
	IfDirExist($tDir);
	$Mode4Seq = "ONT" unless($Mode4Seq);
}

if(1)
{
	open(LOG,"> $File4Log") or die $! unless($File4Log =~ /\.gz$/);
	open(LOG,"| gzip -c > $File4Log") or die $! if($File4Log =~ /\.gz$/);
	
	open(BED,"cat $File4Bed | grep -v ^# |") or die $! unless($File4Bed =~ /\.gz$/);
	open(BED,"zcat $File4Bed | grep -v ^# |") or die $! if($File4Bed =~ /\.gz$/);
	while(my $Line = <BED>)
	{
		chomp $Line;
		my @Cols = split /\t/, $Line;
		next unless($#Cols >= 2);
		next if($Cols[1] =~ /\D/ || $Cols[2] =~ /\D/);
		
		my ($NumOfReads, $MeanDepth) = &AreaInfoFromBam($File4Bam, $Cols[0], $Cols[1], $Cols[2]);
		print LOG join("\t",@Cols[0..2],$NumOfReads, $MeanDepth),"\n";
	}
	close BED;
	
	close LOG;
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########
sub AreaInfoFromBam
{
	my ($Bam,$Chr,$From,$To) = @_;
	
	my $Area = $Chr . ":" . $From . "-" . $To;
	my $Return = "";
	$Return = `bash -c "samtools coverage -b <(ls $Bam) --ff 0xF04 -l 200 -q 20 -Q 7 -r $Area | grep -v ^#"` if($Mode4Seq eq "ONT");
	$Return = `bash -c "samtools coverage -b <(ls $Bam) --ff 0xF04 -l 30 -q 20 -Q 20 -r $Area | grep -v ^#"` if($Mode4Seq eq "NGS");
	chomp $Return;
	my @Items = split /\t/, $Return;
	my $NumOfReads = $Items[3];
	my $MeanDepth = $Items[6];
	$MeanDepth = sprintf("%.1f", $MeanDepth);
	
	return ($NumOfReads,$MeanDepth);
}