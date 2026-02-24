#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my $File4VarList = $ARGV[0];
my $File4Check =  $ARGV[1];
my $Reference = "";
my $Bedtools = "";
# normalization or not;
my $Flag4Norm = 0;

if (1)
{
	# 假如有Header的话需要除去，同时需要补充结束坐标；
	if(1)
	{
		# 统一向3’端标准化;
		my $Ori3Flag = 1;
		open(VL,"zcat $File4VarList | grep -v ^# |") or die $!;
		open(FC,"> $File4Check") or die $!;
		while(my $Line = <VL>)
		{
			chomp $Line;
			my @Cols = split /\t/, $Line;
			die "[ Error ] Columne number not enough.\n" unless($#Cols >= 4);
			
			if($Flag4Norm)
			{
				@Cols[0 .. 4] = &VarUniform($Reference,@Cols[0 .. 4],$Ori3Flag,$Bedtools);
			}
			else
			{
				# must have end pos, '.' could report error invalid file
				if($Cols[2] =~ /[^\d]/)
				{
					if($Cols[3] eq "." || $Cols[4] eq "-")
					{
						$Cols[2] = $Cols[1];
					}
					else
					{
						$Cols[2] = $Cols[1] + length($Cols[3]) - 1;
					}
				}
			}
			print FC join("\t",@Cols),"\n";
		}
		close VL;
		close FC;
	}
}




sub RefGet
{
	my ($RefGen,$Chr,$From,$To,$BedtoolsBin,$OriFlag) = @_;
	
	die "[ Error ] End position can not be smaller than start position when getting seq ($Chr,$From,$To) from ref($RefGen).\n" if($From > $To);
	die "[ Error ] Reference not exist ($RefGen).\n" unless(-e $RefGen);
	$BedtoolsBin = "bedtools" unless($BedtoolsBin);
	
	$From --;
	my $Ref = `echo -e '$Chr\\t$From\\t$To' | $BedtoolsBin getfasta -fi $RefGen -bed - | tail -n 1`;
	chomp $Ref;
	$Ref = uc($Ref) unless($OriFlag);
	
	return $Ref;
}

# 去除多余的碱基;
sub VarSimplify
{
	my ($Chr,$From,$To,$Ref,$Alt) = @_;
	
	if($Ref =~ /^$Alt/ && $Alt ne "*")
	{
		# deletion;
		$From += length($Alt);
		$Ref =~ s/^$Alt//;
		$Alt = "-";
	}
	elsif($Alt =~ /^$Ref/ && $Ref ne "*")
	{
		# insertion;
		$From = $To;
		$Alt =~ s/^$Ref//;
		$Ref = "-";
	}
	$Ref = uc($Ref);
	$Alt = uc($Alt);
	
	if($Ref)
	{
		$To = $From + length($Ref) - 1;
	}
	else
	{
		$To = $From;
	}
	
	return $Chr,$From,$To,$Ref,$Alt;
}

# 将所有的变异都尽量往5'或者3'移动;
sub VarUniform
{
	my ($RefGen,$Chr,$From,$To,$Ref,$Alt,$Ori3Flag,$BedtoolsBin) = @_;
	die "[ Error ] Asterisk * found in Ref or Alt ($Chr,$From,$To,$Ref,$Alt) when var uniform.\n" if($Alt eq "*" || $Ref eq "*");
	
	($Chr,$From,$To,$Ref,$Alt) = &VarSimplify($Chr,$From,$To,$Ref,$Alt);
	if($Ref && $Alt eq "-")
	{
		# deletion;
		if($Ori3Flag)
		{
			# 3’端标准化;
			my $LeftBase = &RefGet($RefGen,$Chr,$From,$From,$BedtoolsBin);
			my $RightBase = &RefGet($RefGen,$Chr,$To + 1,$To + 1,$BedtoolsBin);
			while($LeftBase eq $RightBase)
			{
				$From ++;
				$To ++;
				$LeftBase = &RefGet($RefGen,$Chr,$From,$From,$BedtoolsBin);
				$RightBase = &RefGet($RefGen,$Chr,$To + 1,$To + 1,$BedtoolsBin);
			}
		}
		else
		{
			# 5’端标准化;
			my $LeftBase = &RefGet($RefGen,$Chr,$From - 1,$From - 1,$BedtoolsBin);
			my $RightBase = &RefGet($RefGen,$Chr,$To,$To,$BedtoolsBin);
			while($LeftBase eq $RightBase)
			{
				$From --;
				$To --;
				$LeftBase = &RefGet($RefGen,$Chr,$From - 1,$From - 1,$BedtoolsBin);
				$RightBase = &RefGet($RefGen,$Chr,$To,$To,$BedtoolsBin);
			}
		}
		$Ref = &RefGet($RefGen,$Chr,$From,$To,$BedtoolsBin);
	}
	elsif($Ref eq "-" && $Alt)
	{
		# insertion;
		my $AltLen = length($Alt);
		my @AltBase = split //, $Alt;
		if($Ori3Flag)
		{
			my $tPos = $From;
			my $tBase = &RefGet($RefGen,$Chr,$tPos + 1,$tPos + 1,$BedtoolsBin);
			my $tNum = 0;
			my $tId = $tNum % $AltLen;
			while($tBase eq $AltBase[$tId])
			{
				$tPos ++;
				$tBase = &RefGet($RefGen,$Chr,$tPos + 1,$tPos + 1,$BedtoolsBin);
				$tNum ++;
				$tId = $tNum % $AltLen;
			}
			
			if($tPos > $From)
			{
				$tBase = &RefGet($RefGen,$Chr,$From + 1,$tPos,$BedtoolsBin);
				$tBase = $Alt . $tBase;
				$Alt = substr($tBase,$tPos - $From);
				$From = $tPos;
				$To = $From;
			}
		}
		else
		{
			my $tPos = $From;
			my $tBase = &RefGet($RefGen,$Chr,$tPos,$tPos,$BedtoolsBin);
			my $tNum = 0;
			my $tId = $#AltBase - ($tNum % $AltLen);
			while($tBase eq $AltBase[$tId])
			{
				$tPos --;
				$tBase = &RefGet($RefGen,$Chr,$tPos,$tPos,$BedtoolsBin);
				$tNum ++;
				$tId = $#AltBase - ($tNum % $AltLen);
			}
			
			if($tPos < $From)
			{
				$tBase = &RefGet($RefGen,$Chr,$tPos + 1,$From,$BedtoolsBin);
				$tBase .= $Alt;
				$Alt = substr($tBase,0,$AltLen);
				$From = $tPos;
				$To = $From;
			}
		}
	}
	$Ref = uc($Ref);
	$Alt = uc($Alt);
	
	return $Chr,$From,$To,$Ref,$Alt;
}