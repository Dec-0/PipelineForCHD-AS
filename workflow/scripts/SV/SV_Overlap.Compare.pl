#!/usr/bin/perl
use strict;
use warnings;

# for id generation of sv
my ($Log, $Soft1, $Soft2, $File4FN, $File4FP, $File4TP1, $File4TP2) = @ARGV;

# old ( 1,2342323,INV,Len ID Soft1,Soft2 )
my %SVInfo = ();
my $MaxId = 0;
if(-s $Log)
{
	open(OLD,"cat $Log |") or die $!;
	while(my $Line = <OLD>)
	{
		chomp $Line;
		my @Cols = split /\t/, $Line;
		$SVInfo{$Cols[0]}[0] = $Cols[1];
		$SVInfo{$Cols[0]}[1] = $Cols[2];
		$MaxId = $Cols[1] if ($Cols[1] > $MaxId);
	}
	close OLD;
}

# merge
if(1)
{
	# TP1 and TP2 for both
	if(1)
	{
		open(TPA,"cat $File4TP1 | grep -v ^# |") or die $!;
		open(TPB,"cat $File4TP2 | grep -v ^# |") or die $!;
		while(my $LineA = <TPA>)
		{
			chomp $LineA;
			my $KeyA = &VarInfo($LineA);
			
			my $LineB = <TPB>;
			chomp $LineB;
			my $KeyB = &VarInfo($LineB);
			
			if(defined $SVInfo{$KeyA}[0])
			{
				my $tId = $SVInfo{$KeyA}[0];
				#if(defined $SVInfo{$KeyB}[0])
				#{
				#	die "[ Error ] SVInfo Id of $KeyA ($tId) and $KeyB ($SVInfo{$KeyB}[0]) not same" unless($tId == $SVInfo{$KeyB}[0]);
				#}
				
				$SVInfo{$KeyA}[0] = $tId;
				$SVInfo{$KeyA}[1] = &SoftAdd($SVInfo{$KeyA}[1],$Soft1,$Soft2);
				$SVInfo{$KeyB}[0] = $tId;
				$SVInfo{$KeyB}[1] = &SoftAdd($SVInfo{$KeyB}[1],$Soft1,$Soft2);
			}
			elsif(defined $SVInfo{$KeyB}[0])
			{
				my $tId = $SVInfo{$KeyB}[0];
				#if(defined $SVInfo{$KeyA})
				#{
				#	die "[ Error ] SVInfo Id of $KeyA ($SVInfo{$KeyA}[0]) and $KeyB ($tId) not same" unless($tId == $SVInfo{$KeyA}[0]);
				#}
				
				$SVInfo{$KeyA}[0] = $tId;
				$SVInfo{$KeyA}[1] = &SoftAdd($SVInfo{$KeyA}[1],$Soft1,$Soft2);
				$SVInfo{$KeyB}[0] = $tId;
				$SVInfo{$KeyB}[1] = &SoftAdd($SVInfo{$KeyB}[1],$Soft1,$Soft2);
			}
			else
			{
				$MaxId ++;
				$SVInfo{$KeyA}[0] = $MaxId;
				$SVInfo{$KeyA}[1] = &SoftAdd($SVInfo{$KeyA}[1],$Soft1,$Soft2);
				$SVInfo{$KeyB}[0] = $MaxId;
				$SVInfo{$KeyB}[1] = &SoftAdd($SVInfo{$KeyB}[1],$Soft1,$Soft2);
			}
		}
		close TPA;
		close TPB;
	}
	
	# FN for Soft1 only
	if(1)
	{
		open(FN,"cat $File4FN | grep -v ^# |") or die $!;
		while(my $Line = <FN>)
		{
			chomp $Line;
			my $Key = &VarInfo($Line);
			if(defined $SVInfo{$Key}[0])
			{
				$SVInfo{$Key}[1] = &SoftAdd($SVInfo{$Key}[1],$Soft1,"-")
			}
			else
			{
				$MaxId ++;
				$SVInfo{$Key}[0] = $MaxId;
				$SVInfo{$Key}[1] = $Soft1;
			}
		}
		close FN;
	}
	
	# FP for Soft2 only
	if(1)
	{
		open(FP,"cat $File4FP | grep -v ^# |") or die $!;
		while(my $Line = <FP>)
		{
			chomp $Line;
			my $Key = &VarInfo($Line);
			if(defined $SVInfo{$Key}[0])
			{
				$SVInfo{$Key}[1] = &SoftAdd($SVInfo{$Key}[1],$Soft2,"-")
			}
			else
			{
				$MaxId ++;
				$SVInfo{$Key}[0] = $MaxId;
				$SVInfo{$Key}[1] = $Soft2;
			}
		}
		close FP;
	}
}

# new
if(1)
{
	# 2025.7.22
	# a bug fix: same id but not the same soft list
	my %Id4SoftList = ();
	if (1)
	{
		foreach my $Key (keys %SVInfo)
		{
			my $tId = $SVInfo{$Key}[0];
			if (defined $Id4SoftList{$tId} && $Id4SoftList{$tId})
			{
				$Id4SoftList{$tId} = &SoftListSimple($Id4SoftList{$tId},$SVInfo{$Key}[1]);
			}
			else
			{
				$Id4SoftList{$tId} = $SVInfo{$Key}[1];
			}
		}
	}
	
	open(NEW,"> $Log") or die $!;
	foreach my $Key (keys %SVInfo)
	{
		my $tId = $SVInfo{$Key}[0];
		print NEW join("\t",$Key,$tId,$Id4SoftList{$tId}),"\n";
	}
	close NEW;
}


sub VarInfo
{
	my $Line = $_[0];
	
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	my $SVType = "-";
	$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+);/);
	my $SVLEN = "-";
	if($Cols[7] =~ /SVLEN=([^;]+);/)
	{
		$SVLEN = $1;
	}
	elsif(length($Cols[3]) > length($Cols[4]))
	{
		$SVLEN = length($Cols[3]) - length($Cols[4]);
	}
	$SVLEN = abs($SVLEN) unless($SVLEN =~ /[^-\d]/ || $SVLEN eq "-");
	
	my $Key = join(",",$Cols[0],$Cols[1],$SVType,$SVLEN);
	
	return $Key;
}

sub SoftAdd
{
	my $String = $_[0];
	my $S1 = $_[1];
	my $S2 = $_[2];
	
	my %SoftInfo = ();
	my @tS = ();
	if($String)
	{
		@tS = split /,/, $String;
		for my $i (0 .. $#tS)
		{
			$SoftInfo{$tS[$i]} = 1;
		}
	}
	push @tS, $S1 unless($SoftInfo{$S1} || $S1 eq "-" || $S1 eq "");
	push @tS, $S2 unless($SoftInfo{$S2} || $S2 eq "-" || $S2 eq "");
	
	return join(",",@tS);
}

sub SoftListSimple
{
	my $PreList = $_[0];
	my $CurrList = $_[1];
	
	my $AList = $PreList . "," . $CurrList;
	my $NList = `echo "$AList" | sed 's/,/\\n/g' | sort | uniq | sed ':a;N;s/\\n/,/g;ba'`;
	chomp $NList;
	
	return $NList;
}