#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import os
import sys
import re
import collections
import numpy as np
import pandas as pd

def VarCal(String):
	Cols = String.split(':')
	HVarInfo = collections.defaultdict(list)
	for i in range(0,len(Cols)):
		(Item,Value) = Cols[i].split('=')
		if Value == "NA":
			Value = "."
		HVarInfo[Item] = Value
	
	Ref = HVarInfo['DR']
	if Ref != "." and Ref != "NA" and int(Ref) < 0:
		Ref = "0"
	Alt = HVarInfo['DV']
	Per = "."
	if Ref != "." and Ref != "NA" and Alt != "." and Alt != "NA":
		Full = float(Ref) + float(Alt)
		if Full > 0:
			Per = str("%.2f" % float(float(Alt) / Full))
	
	return [Ref,Alt,Per]


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
		
		Col4Simple = ["String4Dp", "String4Alt", "String4Freq", "MaxDp", "MaxAlt", "MaxFreq"]
		Col4Ref = ['Ref' + Cols[i] for i in range(ColId4Left,ColId4Right)]
		Col4Alt = ['Alt' + Cols[i] for i in range(ColId4Left,ColId4Right)]
		Col4Per = ['Per' + Cols[i] for i in range(ColId4Left,ColId4Right)]
		#HFlt.write('\t'.join(Cols[0:12] + Col4Simple + Col4Ref + Col4Alt + Col4Per + Cols[12:len(Cols)]) + '\n')
		HFlt.write('\t'.join(Cols[0:ColId4Left] + Col4Simple + Cols[ColId4Left:len(Cols)]) + '\n')
		Line = HOri.readline()
		while Line:
			Cols = Line.split('\t')
			Value4Ref, Value4Alt, Value4Per = [], [], []
			for i in range(ColId4Left,ColId4Right):
				# GT=0/1:GQ=.:DR=46:DV=5
				Values = VarCal(Cols[i])
				Value4Ref.append(Values[0])
				Value4Alt.append(Values[1])
				Value4Per.append(Values[2])
			# all ref, alt, freq;
			EffectDp, EffectAlt, EffectFreq = [], [], []
			for i in range(len(Value4Ref)):
				if Value4Ref[i] != "." and Value4Alt[i] != ".":
					EffectDp.append(str(int(Value4Ref[i]) + int(Value4Alt[i])))
				if Value4Alt[i] != ".":
					EffectAlt.append(Value4Alt[i])
				if Value4Per[i] != ".":
					EffectFreq.append(Value4Per[i])
			String4Dp = ','.join(EffectDp)
			String4Alt = ','.join(EffectAlt)
			String4Freq = ','.join(EffectFreq)
			#print("%s %s %s" % (String4Dp, String4Alt, String4Freq))
			# max ref, alt, freq;
			MaxDp, MaxAlt, MaxFreq = ".", ".", "."
			for i in range(len(EffectDp)):
				if MaxDp == ".":
					MaxDp = EffectDp[i]
				elif EffectDp[i] != ".":
					if float(EffectDp[i]) > float(MaxDp):
						MaxDp = EffectDp[i]
			for i in range(len(EffectAlt)):
				if MaxAlt == ".":
					MaxAlt = EffectAlt[i]
				elif EffectAlt[i] != ".":
					if float(EffectAlt[i]) > float(MaxAlt):
						MaxAlt = EffectAlt[i]
			for i in range(len(EffectFreq)):
				if MaxFreq == ".":
					MaxFreq = EffectFreq[i]
				elif EffectFreq[i] != ".":
					if float(EffectFreq[i]) > float(MaxFreq):
						MaxFreq = EffectFreq[i]
			String4All = [String4Dp, String4Alt, String4Freq, MaxDp, MaxAlt, MaxFreq]
			#HFlt.write('\t'.join(Cols[0:12] + String4All + Value4Ref + Value4Alt + Value4Per + Cols[12:len(Cols)]))
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