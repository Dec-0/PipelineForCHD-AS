#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my $File4VarList = $ARGV[0];
my $File4AnnoOri = $ARGV[1];
my $File4Anno = $ARGV[2];

if (1)
{
	# 格式转换；
	if(1)
	{
		my $AnnoHeader = "#";
		my $Col4OtherInfo = 0;
		my $ColExceedFlag = 0;
		if(1)
		{
			my $tHeader = `cat $File4AnnoOri | head -n1`;
			chomp $tHeader;
			my @tItems = split /\t/, $tHeader;
			for my $i (5 .. $#tItems)
			{
				if($tItems[$i] eq "Otherinfo1")
				{
					$Col4OtherInfo = $i;
					last;
				}
			}
			# 没有otherinfo1时表示没有第6列，直接标记额外列号就号;
			if($Col4OtherInfo == 0)
			{
				$Col4OtherInfo = @tItems;
				$ColExceedFlag = 1;
			}
			my @Items = @tItems[0 .. 4];
			for my $i ($Col4OtherInfo .. $#tItems)
			{
				push @Items, $tItems[$i];
			}
			for my $i (5 .. $Col4OtherInfo - 1)
			{
				push @Items, $tItems[$i];
			}
			
			my %ConvertInfo = ("Func_refGene" => "Func","Gene_refGene" => "Gene","GeneDetail_refGene" => "GeneDetail","ExonicFunc_refGene" => "ExonicFunc","AAChange_refGene" => "AAChange",
			"esp6500siv2_all" => "AF_ESP6500",
			"AF" => "AF_gnomAD","AF_popmax" => "AF_gnomAD_popmax","AF_male" => "AF_gnomAD_male","AF_female" => "AF_gnomAD_female","AF_raw" => "AF_gnomAD_raw","AF_afr" => "AF_gnomAD_African","AF_sas" => "AF_gnomAD_SouthAsia","AF_amr" => "AF_gnomAD_AdmixAmerican","AF_eas" => "AF_gnomAD_EastAsia","AF_nfe" => "AF_gnomAD_NonFinnishEuropean","AF_fin" => "AF_gnomAD_Finnish","AF_asj" => "AF_gnomAD_AshkenaziJewish","AF_oth" => "AF_gnomAD_Other","non_topmed_AF_popmax" => "AF_gnomAD_NonTOPMed","non_neuro_AF_popmax" => "AF_gnomAD_NonNeuro","non_cancer_AF_popmax" => "AF_gnomAD_NonCancer","controls_AF_popmax" => "AF_gnomAD_Contrl",
			"ALL.sites.2015_08" => "AF_1000g_ALL","EAS.sites.2015_08" => "AF_1000g_EastAsia","SAS.sites.2015_08" => "AF_1000g_SouthAsia","EUR.sites.2015_08" => "AF_1000g_Europe","AMR.sites.2015_08" => "AF_1000g_America","AFR.sites.2015_08" => "AF_1000g_Africa",
			"CLNALLELEID" => "Clinvar_ID","CLNDN" => "Clinvar_Name","CLNDISDB" => "Clinvar_DiseaseDBNameAndIdentifier","CLNREVSTAT" => "Clinvar_ReviewStatus","CLNSIG" => "Clinvar_Significant"
			);
			my $tColId = 5;
			$tColId += $#tItems - $Col4OtherInfo + 1 unless($ColExceedFlag);
			for my $i ($tColId .. $#Items)
			{
				next unless($ConvertInfo{$Items[$i]});
				$Items[$i] = $ConvertInfo{$Items[$i]};
			}
			
			$AnnoHeader .= join("\t",@Items);
		}
		# 确定Header部分标签，假如有原始标签就用原始标签；
		my $Header = "";
		$Header = `cat $File4VarList | awk '{if(/^#/){print \$0}else{exit;}}'` unless($File4VarList =~ /\.gz$/);
		$Header = `zcat $File4VarList | awk '{if(/^#/){print \$0}else{exit;}}'` if($File4VarList =~ /\.gz$/);
		chomp $Header;
		if($Header)
		{
			if($Header =~ /\n/)
			{
				my @Cols = split /\n/, $Header;
				$Header = $Cols[-1];
			}
			
			my @Items = split /\t/, $AnnoHeader;
			my @Cols = split /\t/, $Header;
			for my $i (5 .. $#Cols)
			{
				$Items[$i] = $Cols[$i];
			}
			$AnnoHeader = join("\t",@Items);
		}
		
		open(ANNOB,"cat $File4AnnoOri |") or die $!;
		open(RA,"> $File4Anno") or die $!;
		<ANNOB>;
		print RA $AnnoHeader,"\n";
		while(my $Line = <ANNOB>)
		{
			chomp $Line;
			my @Cols = split /\t/, $Line;
			print RA join("\t",@Cols[0 .. 4],@Cols[$Col4OtherInfo .. $#Cols],@Cols[5 .. $Col4OtherInfo - 1]),"\n";
		}
		close ANNOB;
		close RA;
	}
}