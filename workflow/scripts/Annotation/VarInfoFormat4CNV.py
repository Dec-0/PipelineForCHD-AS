#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import os
import sys
import re
import collections
import numpy as np
import pandas as pd

# for CNV
def VarCal(String):
	Cols = String.split(':')
	HVarInfo = collections.defaultdict(list)
	for i in range(0,len(Cols)):
		(Item,Value) = Cols[i].split('=')
		if Value == "NA":
			Value = "."
		HVarInfo[Item] = Value
	
	Bins = HVarInfo['DR']
	CN = HVarInfo['DV']
	
	return [Bins,CN]


def VarFormat(File4Ori,File4Flt):
	HFlt = open(File4Flt,"w")
	with open(File4Ori,"r") as HOri:
		Cols = HOri.readline().strip('\n').split('\t')
		ColId4Left = '-'
		for i in range(len(Cols)):
			if Cols[i] == "Sample_ID":
				ColId4Left = i + 1
				break
		ColId4Right = '-'
		for i in range(len(Cols)):
			if Cols[i] == "HPO_ITEM":
				ColId4Right = i
				break
		print("[ Info ] Left and right column id for samples are: %s and %s" % (ColId4Left, ColId4Right))
		
		Col4Simple = ["String4Bins", "String4CopyNum", "MaxBins", "MaxCopyNum"]
		HFlt.write('\t'.join(Cols[0:ColId4Left] + Col4Simple + Cols[ColId4Left:len(Cols)]) + '\n')
		Line = HOri.readline()
		while Line:
			Cols = Line.split('\t')
			Value4Bins, Value4CN = [], []
			for i in range(ColId4Left,ColId4Right):
				# GT=0/1:GQ=.:DR=46:DV=5
				Values = VarCal(Cols[i])
				Value4Bins.append(Values[0])
				Value4CN.append(Values[1])
			# all Bins, CN;
			EffectBins, EffectCN = [], []
			for i in range(len(Value4Bins)):
				if Value4Bins[i] != ".":
					EffectBins.append(Value4Bins[i])
				if Value4CN[i] != ".":
					EffectCN.append(Value4CN[i])
			String4Bins = ','.join(EffectBins)
			String4CN = ','.join(EffectCN)
			# max Bins, CN;
			MaxBins, MaxCN = ".", "."
			for i in range(len(EffectBins)):
				if MaxBins == ".":
					MaxBins = EffectBins[i]
				elif EffectBins[i] != ".":
					if float(EffectBins[i]) > float(MaxBins):
						MaxBins = EffectBins[i]
			for i in range(len(EffectCN)):
				if MaxCN == ".":
					MaxCN = EffectCN[i]
				elif EffectCN[i] != ".":
					if float(EffectCN[i]) > float(MaxCN):
						MaxCN = EffectCN[i]
			String4All = [String4Bins, String4CN, MaxBins, MaxCN]
			HFlt.write('\t'.join(Cols[0:12] + String4All + Cols[12:len(Cols)]))
			Line = HOri.readline()
	HFlt.close()


def main():
	if len(sys.argv) != 3:
		print("[ Error ] Not enough arguments (%s)" % len(sys.argv))
		sys.exit()
	
	VarFormat(sys.argv[1], sys.argv[2])


if __name__ == '__main__':
	main()