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
my ($File4Bam,$File4Log,$File4SNPList,$ThreadsNum,$MinY,$Samtools);
my $ThisScriptName = basename $0;
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script was used to confirm the gender from bam file.

 -bam    ( Required ) File for bam;
 -log    ( Required ) File for logging;

 -t      ( Optional ) Number of threads (default: 10);
 -min    ( Optional ) Minimal Y percent (default: 0.05);
 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'bam=s' => \$File4Bam,
	'log=s' => \$File4Log,
	't:i' => \$ThreadsNum,
	'min:i' => \$MinY,
	'list:s' => \$File4SNPList,
	'st:s' => \$Samtools,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || ! $File4Bam || ! $File4Log)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	
	$BinList = BinListGet() if(!$BinList);
	$File4SNPList = BinSearch("SNPList", $BinList) unless($File4SNPList);
	$ThreadsNum = BinSearch("ThreadsNum", $BinList) unless($ThreadsNum);
	$MinY = BinSearch("MinY", $BinList, 1) unless($MinY);
	$Samtools = BinSearch("Bin4Samtools", $BinList) unless($Samtools);
	
	IfFileExist($File4Bam);
	my $tDir = dirname $File4Log;
	IfDirExist($tDir);
}

if(1)
{
	open(LOG,"> $File4Log") or die $!;
	print LOG join("\t","#Chr","Sum","Num","Mean"),"\n";
	
	`zcat $File4SNPList | awk -F '\t' '{Start = \$2 - 1;print \$1"\t"Start"\t"\$2 }' > $File4Log\.tmp.bed`;
	`$Samtools depth -a -q 7 -Q 20 -@ $ThreadsNum -b $File4Log\.tmp.bed $File4Bam > $File4Log\.tmp.depth.txt`;
	
	my %ChrMean = ();
	my ($AutoSum, $AutoNum, $AutoMean) = (0, 0, 0);
	my @ChrStr = ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "X", "Y");
	for my $i (0 .. $#ChrStr)
	{
		my $tInfo = `cat $File4Log\.tmp.depth.txt | awk -F '\t' -v NC="$ChrStr[$i]" 'BEGIN{Sum = 0;Num = 0;Mean = 0;}{if(\$1 == NC){Sum += \$3; Num += 1;}}END{Mean = Sum / Num;print Sum"\t"Num"\t"Mean }'`;
		chomp $tInfo;
		my ($Sum, $Num, $Mean) = split /\t/, $tInfo;
		$Mean = sprintf("%.4f", $Mean);
		print LOG join("\t",$ChrStr[$i],$Sum,$Num,$Mean),"\n";
		
		$ChrMean{$ChrStr[$i]} = $Mean;
		$AutoSum += $Sum if($i <= 21);
		$AutoNum += $Num if($i <= 21);
	}
	
	my $Gender = "Female";
	$AutoMean = sprintf("%.4f", $AutoSum / $AutoNum);
	$Gender = "Male" if($ChrMean{"Y"} / $AutoMean > $MinY);
	print LOG join("\t","Gender","-","-",$Gender),"\n";
	
	close LOG;
	
	`rm $File4Log\.tmp.bed` if(-s "$File4Log\.tmp.bed");
	`rm $File4Log\.tmp.depth.txt` if(-s "$File4Log\.tmp.depth.txt");
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########