#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
Getopt::Long::Configure qw(no_ignore_case);
use File::Basename;
use threads;
use FindBin qw($Bin);
use lib "$Bin/.Modules";
use Parameter::BinList;

my ($HelpFlag,$BinList,$BeginTime);
my ($File4Bam,$File4Bed,$File4BedExtend,$SPName,$File4Log,$MaxThreadNum,$Bed4Genome);
my ($Bin4Samtools,$Bin4Bedtools,$Bin4fxTools);
my $ThisScriptName = basename $0;
my $HelpInfo = <<USAGE;

 $ThisScriptName
 Auther: zhangdong_xie\@foxmail.com

  This script was used for the QC of ONT Adaptive Sampling Bam file.
  
  Compared with v1.0.3:
  1. FragmentNInfo revision. Threads number changed from hard-code to assign. Deprecate head -n;
  
  Compared with v1.0.2:
  1. Shrink Off-target area in case impacted by on-target info when statistic fragment size distribution;
  
  Compared with v1.0:
  1. add info of total bases and reads;
  2. add mappability rate;

 -bam    ( Required ) Bam file;
 -bed    ( Required ) Panel bed file;
 -name   ( Required ) SP name;
 -log    ( Required ) File for logging;

 -t      ( Optional ) Threads number;
 -g      ( Optional ) Bed file for genome;
 -bin    ( Optional ) List for searching of related bin or scripts; 
 -h      ( Optional ) Help infomation;

USAGE

GetOptions(
	'bam=s' => \$File4Bam,
	'bed=s' => \$File4Bed,
	'extend=s' => \$File4BedExtend,
	'name=s' => \$SPName,
	'log=s' => \$File4Log,
	't:i' => \$MaxThreadNum,
	'g:s' => \$Bed4Genome,
	'smt:s' => \$Bin4Samtools,
	'bt:s' => \$Bin4Bedtools,
	'fxt:s' => \$Bin4fxTools,
	'bin:s' => \$BinList,
	'h!' => \$HelpFlag
) or die $HelpInfo;

if($HelpFlag || ! $File4Bam || ! $File4Bed || ! $File4BedExtend || ! $SPName || ! $File4Log)
{
	die $HelpInfo;
}
else
{
	$BeginTime = ScriptBegin(0,$ThisScriptName);
	
	$BinList = BinListGet() if(!$BinList);
	$Bed4Genome = BinSearch("Bed4Genome",$BinList) unless($Bed4Genome);
	IfFileExist($File4Bam,$File4Bed,$File4BedExtend,$Bed4Genome);
	my $tDir = dirname $File4Log;
	IfDirExist($tDir);
	$MaxThreadNum = BinSearch("MaxThreadNum",$BinList,1) unless($MaxThreadNum);
	$Bin4Samtools = BinSearch("Samtools",$BinList) unless($Bin4Samtools);
	$Bin4Bedtools = BinSearch("Bedtools",$BinList) unless($Bin4Bedtools);
	$Bin4fxTools = BinSearch("fxTools",$BinList) unless($Bin4fxTools);
	
	print "[ Info ] Bed for genome: $Bed4Genome\n";
	print "[ Info ] Bam: $File4Bam\n";
	print "[ Info ] Bed for panel: $File4Bed\n";
	print "[ Info ] Bed for panel extended: $File4BedExtend\n";
	print "[ Info ] File for result: $File4Log\n";
	print "[ Info ] Number of threads: $MaxThreadNum\n";
}

if(1)
{
	open(LOG,"> $File4Log") or die $!;
	print LOG "Items\t$SPName\n";
	
	# pannel size of on-target and off-target
	if(1)
	{
		my $SizeOnTarget = &OneBedSize($File4Bed);
		print LOG "On-target size(bp):\t$SizeOnTarget\n";
		
		# 2024.7.1 change from OneBedSize to FirstBedExclusiveSize (bug)
		my $SizeOffTarget = &FirstBedExclusiveSize($Bed4Genome,$File4Bed);
		print LOG "Off-target size(bp):\t$SizeOffTarget\n";
		
		my $TargetPer = "-";
		$TargetPer = sprintf("%.4f", $SizeOnTarget / ($SizeOnTarget + $SizeOffTarget)) if($SizeOnTarget + $SizeOffTarget > 0);
		print LOG "Percent of target size:\t$TargetPer\n";
	}
	
	# base info
	if(1)
	{
		my ($ReadsTotal, $ReadsMapped, $ReadsMapRate, $BaseTotal, $BaseMapped, $BaseMapRate, $BaseMappedCigar, $BaseMapRateCigar) = &BamBaseInfo($File4Bam, $File4Log);
		print LOG "Total reads:\t$ReadsTotal\n";
		print LOG "Mapped reads:\t$ReadsMapped\n";
		print LOG "Map rate (reads):\t$ReadsMapRate\n";
		print LOG "Total bases:\t$BaseTotal\n";
		print LOG "Mapped bases:\t$BaseMapped\n";
		print LOG "Map rate (bases):\t$BaseMapRate\n";
		print LOG "Mapped bases(cigar):\t$BaseMappedCigar\n";
		print LOG "Map rate (bases, cigar):\t$BaseMapRateCigar\n";
	}
	
	# reads on-target and off-target
	# bases on-target and off-target
	if(1)
	{
		my ($NumOfReads_On,$StdNumOfReads_On,$NumOfBases_On,$MeanCov_On,$CovRate_On) = &BamBedInfoCollect($File4Bam, $File4Bed);
		print LOG "Number of reads On-target:\t$NumOfReads_On\n";
		print LOG "Number of bases On-target:\t$NumOfBases_On\n";
		print LOG "Standardized number of reads On-target:\t$StdNumOfReads_On\n";
		print LOG "Mean coverage On-target:\t$MeanCov_On\n";
		print LOG "Cover-rate of On-target:\t$CovRate_On\n";
		
		my ($NumOfReads_Off,$StdNumOfReads_Off,$NumOfBases_Off,$MeanCov_Off,$CovRate_Off) = &BamBedInfoCollect($File4Bam, $Bed4Genome, $File4Bed);
		print LOG "Number of reads Off-target:\t$NumOfReads_Off\n";
		print LOG "Number of bases Off-target:\t$NumOfBases_Off\n";
		print LOG "Standardized number of reads Off-target:\t$StdNumOfReads_Off\n";
		print LOG "Mean coverage Off-target:\t$MeanCov_Off\n";
		print LOG "Cover-rate of Off-target:\t$CovRate_Off\n";
		
		my ($BasePer_On, $BasePer_Off) = ("-", "-");
		$BasePer_On = sprintf("%.4f", $NumOfBases_On / ($NumOfBases_On + $NumOfBases_Off)) if($NumOfBases_On + $NumOfBases_Off > 0);
		$BasePer_Off = sprintf("%.4f", $NumOfBases_Off / ($NumOfBases_On + $NumOfBases_Off)) if($NumOfBases_On + $NumOfBases_Off > 0);
		print LOG "Percent of bases On-target:\t$BasePer_On\n";
		print LOG "Percent of bases Off-target:\t$BasePer_Off\n";
		
		my $EnrichRate = "-";
		$EnrichRate = sprintf("%.4f", $MeanCov_On / $MeanCov_Off) if($MeanCov_Off > 0);
		print LOG "On/Off enrich rate:\t$EnrichRate\n";
	}
	
	# N10 to N90
	if(1)
	{
		my %NInfo_On = %{&FragmentNInfo($File4Bam, $File4Bed)};
		my %NInfo_Off = %{&FragmentNInfo($File4Bam, $Bed4Genome, $File4BedExtend)};
		for my $i (1 .. 9)
		{
			my $Tag = "N$i" . "0";
			print LOG "$Tag of On-target:\t$NInfo_On{$Tag}\n";
		}
		for my $i (1 .. 9)
		{
			my $Tag = "N$i" . "0";
			print LOG "$Tag of Off-target:\t$NInfo_Off{$Tag}\n";
		}
	}
	
	close LOG;
}
printf "[ %s ] The end.\n",TimeString(time,$BeginTime);


######### Sub functions ##########
sub OneBedSize
{
	my $tBed = $_[0];
	
	my $tSize = `cat $tBed | awk -F '\t' 'BEGIN{Sum = 0;}{Sum += \$3 - \$2;}END{print Sum}'`;
	chomp $tSize;
	
	return $tSize;
}

sub FirstBedExclusiveSize
{
	my $tBed1 = $_[0];
	my $tBed2 = $_[1];
	
	my $tSize = `$Bin4Bedtools multiinter -i $tBed1 $tBed2 | awk '{if(\$6 == 1 && \$7 == 0){print}}' | awk -F '\t' 'BEGIN{Sum = 0;}{Sum += \$3 - \$2;}END{print Sum}'`;
	chomp $tSize;
	
	return $tSize;
}

sub BamBaseInfo
{
	my $Bam = $_[0];
	my $File = $_[1];
	
	my $tFile = $File . ".tmpBamBaseInfo";
	`$Bin4Samtools stats -@ 20 $Bam > $tFile`;
	
	my $ReadsTotal = `cat $tFile | grep ^SN | cut -f 2- | grep ^'raw total sequences:' | cut -f 2`;
	chomp $ReadsTotal;
	my $ReadsMapped = `cat $tFile | grep ^SN | cut -f 2- | grep ^'reads mapped:' | cut -f 2`;
	chomp $ReadsMapped;
	my $ReadsMapRate = "-";
	$ReadsMapRate = sprintf("%.4f", $ReadsMapped / $ReadsTotal) if($ReadsTotal > 0);
	
	my $BaseTotal = `cat $tFile | grep ^SN | cut -f 2- | grep ^'total length:' | cut -f 2`;
	chomp $BaseTotal;
	my $BaseMapped = `cat $tFile | grep ^SN | cut -f 2- | grep ^'bases mapped:' | cut -f 2`;
	chomp $BaseMapped;
	my $BaseMapRate = "-";
	$BaseMapRate = sprintf("%.4f", $BaseMapped / $BaseTotal) if($BaseTotal > 0);
	
	my $BaseMappedCigar = `cat $tFile | grep ^SN | cut -f 2- | grep ^'bases mapped (cigar):' | cut -f 2`;
	chomp $BaseMappedCigar;
	my $BaseMapRateCigar = "-";
	$BaseMapRateCigar = sprintf("%.4f", $BaseMappedCigar / $BaseTotal) if($BaseTotal > 0);
	
	`rm $tFile` if(-s $tFile);
	
	return ($ReadsTotal, $ReadsMapped, $ReadsMapRate, $BaseTotal, $BaseMapped, $BaseMapRate, $BaseMappedCigar, $BaseMapRateCigar);
}

sub BamBedInfoCollect
{
	my ($Bam,$Bed1,$Bed2,$Other) = @_;
	
	my ($NumOfReads,$NumOfBases,$TotalSize,$CovSize) = (0,0,0,0);
	# each bed line
	my $tNum = 0;
	printf "[ %s ] Begin BamBedInfoCollect.\n",TimeString(time,$BeginTime);
	open(BED,"$Bin4Bedtools multiinter -i $Bed1 $Bed2 | awk '{if(\$6 == 1 && \$7 == 0){print}}' | $Bin4Bedtools sort -i - | $Bin4Bedtools merge -d 0 -i - |") or die $! if($Bed2 && -s $Bed2);
	open(BED,"cat $Bed1 |") or die $! unless($Bed2 && -s $Bed2);
	while(my $Line = <BED>)
	{
		chomp $Line;
		my @Cols = split /\t/, $Line;
		my $Area = $Cols[0] . ":" . $Cols[1] . "-" . $Cols[2];
		
		my $CurrentThreadNum = scalar(threads->list(threads::running));
		while ($CurrentThreadNum >= $MaxThreadNum)
		{
			sleep 1;
			$CurrentThreadNum = scalar(threads->list(threads::running));
		}
		foreach my $thread (threads->list(threads::joinable))
		{
			my $Return = ($thread->join());
			my @Items = split /\t/, $Return;
			$NumOfReads += $Items[3];
			$CovSize += $Items[4];
			$TotalSize += $Items[2] - $Items[1];
			$NumOfBases += int($Items[6] * ($Items[2] - $Items[1]));
			
			$tNum ++;
			if($tNum % 1000 == 0)
			{
				printf "[ %s ] Processed %d.\n",TimeString(time,$BeginTime),$tNum;
			}
		}
		my $Obj4Thread = threads->create(\&SamCov,$Bam,$Area);
	}
	close BED;
	foreach my $thread (threads->list())
	{
		my $Return = ($thread->join());
		my @Items = split /\t/, $Return;
		$NumOfReads += $Items[3];
		$CovSize += $Items[4];
		$TotalSize += $Items[2] - $Items[1];
		$NumOfBases += int($Items[6] * ($Items[2] - $Items[1]));
		
		$tNum ++;
		if($tNum % 1000 == 0)
		{
			printf "[ %s ] Processed %d.\n",TimeString(time,$BeginTime),$tNum;
		}
	}
	
	my $CovRate = "-";
	$CovRate = sprintf("%.4f", $CovSize / $TotalSize) if($TotalSize > 0);
	my $MeanCov = "-";
	$MeanCov = sprintf("%.4f", $NumOfBases / $TotalSize) if($TotalSize > 0);
	my $StdNumOfReads = "-";
	$StdNumOfReads = sprintf("%.8f", $NumOfReads / $TotalSize) if($TotalSize > 0);
	
	return ($NumOfReads,$StdNumOfReads,$NumOfBases,$MeanCov,$CovRate);
}

sub SamCov
{
	my ($Bam,$Area,$Other) = @_;
	
	my $Return = `bash -c "$Bin4Samtools coverage -b <(ls $Bam) -l 200 -q 20 -Q 7 -r $Area | grep -v ^#"`;
	chomp $Return;
	
	return $Return;
}

sub FragmentNInfo
{
	my ($Bam,$Bed1,$Bed2) = @_;
	my %NInfo = ();
	
	my $Return = "-";
	$Return = `bash -c "$Bin4Samtools view -hb -q 20 -@ $MaxThreadNum -L $Bed1 $Bam | $Bin4Samtools fasta -s /dev/stdout -F 0xF40 -n -@ $MaxThreadNum | head -n 4000000 | $Bin4fxTools stat -m 0 | grep ^N | sed -E 's/\\s+/\t/g' | cut -f 1,3"` unless($Bed2 && -s $Bed2);
	$Return = `bash -c "$Bin4Samtools view -hb -q 20 -@ $MaxThreadNum -L <($Bin4Bedtools multiinter -i $Bed1 $Bed2 | awk '{if(\\\$6 == 1 && \\\$7 == 0){print}}' | cut -f 1-3) $Bam | $Bin4Samtools fasta -s /dev/stdout -F 0xF40 -n -@ $MaxThreadNum | head -n 4000000 | $Bin4fxTools stat -m 0 | grep ^N | sed -E 's/\\s+/\t/g' | cut -f 1,3"` if($Bed2 && -s $Bed2);
	
	chomp $Return;
	my @Cols = split /\n/, $Return;
	for my $i (0 .. $#Cols)
	{
		my @Items = split /\t/, $Cols[$i];
		$NInfo{$Items[0]} = $Items[1];
	}
	
	return \%NInfo;
}