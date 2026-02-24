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
	Flag4Insert = False
	for Line in OriLines:
		# comment line
		Line = Line.decode('utf8')
		if re.match('#',Line):
			if re.match('##FORMAT=<ID=',Line):
				Flag4Insert = True
			if re.match('##FORMAT=<ID=',Line) is None and Flag4Insert:
				Flag4Insert = False
				HAdd.write("##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Number of all reads\">\n")
				HAdd.write("##FORMAT=<ID=DR,Number=1,Type=Integer,Description=\"Number of reference reads\">\n")
				HAdd.write("##FORMAT=<ID=DV,Number=1,Type=Integer,Description=\"Number of variant reads\">\n")
			HAdd.write(Line)
			continue
		
		# variant line
		Cols = Line.strip('\n').split('\t')
		DP = DepthGet(HBam,Cols[0],Cols[1])
		# DR, DV
		(DR,DV) = ('.', '.')
		CatchInfo = re.search('SUPPREAD=([^;]+)',Cols[7])
		if CatchInfo is not None:
			DV = CatchInfo.group(1)
			DR = int(DP) - int(DV)
		
		Cols[8] += ':DP:DR:DV'
		Cols[9] += ':' + str(DP) + ':' + str(DR) + ':' + str(DV)
		HAdd.write('\t'.join(Cols) + '\n')
	HOri.close()
	HAdd.close()

if __name__ == '__main__':
	main()