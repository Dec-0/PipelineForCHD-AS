#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import os
import sys
import re
import pickle
import random
import gzip
import numpy as np
import pandas as pd
import pysam

def SafeOpen(FileName,Mode):
    try:
        if not FileName.endswith('.gz'):
            return open(FileName,Mode)
        else:
            import gzip
            return gzip.open(FileName,Mode)
    except IOError:
        print(FileName + ' do not exist!')

def DepthGet(tHBam,tChr,tPos):
	Cov = tHBam.count(str(tChr),int(tPos)-1,int(tPos))
	return Cov

def main():
	if len(sys.argv) != 4:
		NumOfArgv = len(sys.argv) - 1
		print("[ Warning ] Numer of arguments should be 3 (%i)" % NumOfArgv)
		sys.exit()
	
	(OriVcf, Bam, AddVcf) = sys.argv[1:]
	print("[ OriVcf ] %s" % OriVcf)
	print("[ Bam ] %s" % Bam)
	print("[ AddVcf ] %s" % AddVcf)
	
	HBam = pysam.AlignmentFile(Bam,"rb")
	
	HOri = SafeOpen(OriVcf,'r')
	HAdd = SafeOpen(AddVcf,'w')
	OriLines = HOri.readlines()
	for Line in OriLines:
		# comment line
		Line = Line.decode('utf8')
		if re.match('#',Line):
			HAdd.write(Line)
			continue
		
		# variant line
		Cols = Line.strip('\n').split('\t')
		DP = DepthGet(HBam,Cols[0],Cols[1])
		# DR, DV
		Values = Cols[-1].split(":")
		DR = int(DP) - int(Values[2])
		if DR < 0:
			DR = 0
		Values[1] = str(DR)
		Cols[-1] = ':'.join(Values)
		
		HAdd.write('\t'.join(Cols) + '\n')
	HOri.close()
	HAdd.close()

if __name__ == '__main__':
	main()