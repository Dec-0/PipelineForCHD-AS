#!/usr/bin/perl
use strict;
use warnings;

# for id generation of sv
my ($Log, $VcfOri, $VcfFlt, $Bin4bgzip) = @ARGV;
$Bin4bgzip = "bgzip" unless($Bin4bgzip);

# old ( 1,2342323,INV,Len ID Soft1,Soft2 )
my %SVInfo = ();
if(1)
{
	open(OLD,"cat $Log |") or die $!;
	while(my $Line = <OLD>)
	{
		chomp $Line;
		my @Cols = split /\t/, $Line;
		$SVInfo{$Cols[0]} = "Yes";
	}
	close OLD;
}

# filter
if(1)
{
	# TP1 and TP2 for both
	if(1)
	{
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
			my $Key = &VarInfo($Line);
			next unless(defined $SVInfo{$Key});
			next unless($SVInfo{$Key} eq "Yes");
			
			# pbsv.BND in the same chr are removed
			#next unless(&BNDSameChrinPbsv($Line));
			
			print FLT $Line,"\n";
		}
		close ORI;
		close FLT;
	}
}


sub VarInfo
{
	my $Line = $_[0];
	
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	my $SVType = "-";
	$SVType = $1 if($Cols[7] =~ /SVTYPE=([^;]+)/);
	my $SVLEN = "-";
	if($Cols[7] =~ /SVLEN=([^;]+)/)
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

sub BNDSameChrinPbsv
{
	my $Line = $_[0];
	
	my $SaveFlag = 1;
	chomp $Line;
	my @Cols = split /\t/, $Line;
	
	if($Cols[2] =~ /pbsv.BND/)
	{
		my @Items = split /\./, $Cols[2];
		my @Pairs = split /-/, $Items[-1];
		my ($Chr1,$Pos1) = split /:/, $Pairs[0];
		my ($Chr2,$Pos2) = split /:/, $Pairs[1];
		$SaveFlag = 0 if($Chr1 eq $Chr2);
	}
	
	return $SaveFlag;
}