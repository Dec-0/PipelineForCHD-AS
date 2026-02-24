#!/usr/bin/perl
use strict;
use warnings;


# 有时SV结果里有很长的DEL和INS，此时AnnotSV注释会崩溃，需要改为“ N <DEL> ”这种记录SVTYPE的格式
# 比如CHD_WGS项目中debreak报出的就是记录SVTYPE的格式，但是CHD_Panel项目中debreak报出的是具体的序列格式
# 暂时只改变DEL/INS/DUP/INV，BND或者TRA不变，以免影响后续的坐标提取（cuteSV在INFO列并没有记录配对坐标信息）。
my $VcfOri = $ARGV[0];
my $VcfRevise = $ARGV[1];
my $Bin4bgzip = $ARGV[2];
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
	
	# if SVType then change
	my $SVType = "-";
	$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;\t]+)/);
	
	if ($SVType eq "INS" || $SVType eq "DEL" || $SVType eq "DUP" || $SVType eq "INV")
	{
		$Cols[3] = "N";
		$Cols[4] = "<" . $SVType . ">";
		$Line = join("\t",@Cols);
		print REV $Line;
	}
	else
	{
		print REV $Line;
	}
}
close ORI;
close REV;
