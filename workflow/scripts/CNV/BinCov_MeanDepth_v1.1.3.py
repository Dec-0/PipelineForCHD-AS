#!/usr/bin/python
import argparse
import pysam
import time
import sys
import os
import numpy as np
import collections
from pathlib import Path


class MyParser(argparse.ArgumentParser):
	def error(self, message):
		sys.stderr.write('error: %s\n' % message)
		self.print_help()
		sys.exit(2)

def Second2String(DurTime):
	DurTime = int(DurTime)
	Stamp = ''
	Day = int(DurTime / 86400)
	if Day :
		Stamp = str(Day) + 'd'
		DurTime = DurTime % 86400
	Hour = int(DurTime / 3600)
	if Hour :
		if Stamp :
			Stamp = Stamp + str(Hour) + 'h'
		else :
			Stamp = str(Hour) + 'h'
	DurTime = DurTime % 3600
	Min = int(DurTime / 60)
	if Min :
		if Stamp :
			Stamp = Stamp + str(Min) + 'm'
		else :
			Stamp = str(Min) + 'min'
	Sec = DurTime % 60
	if Sec :
		if Stamp :
			Stamp = Stamp + str(Sec) + 's'
		else :
			Stamp = str(Sec) + 'sec'
	
	if not Stamp:
		Stamp = '0s'
	
	return Stamp

def IfFileExist(String):
	Flag = 0
	if String and Path(String).exists :
		if Path(String).is_file() :
			Flag = 1
	
	return Flag

def BinCount(File4Bam, File4BedS, File4LogS, NumOfThreads, MinMapQ, MinBaseQ, MinReadLen, File4DepthPanel, Flag4TempSave):
	# WGS Depth
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	File4WGSDepth = File4LogS[0] + ".tmpDepth4WGS.txt"
	if IfFileExist(File4DepthPanel):
		print("[ %s ] Begin depth info collect from panel." % TimeStamp)
		pysam.depth("-q",str(MinBaseQ),"-Q",str(MinMapQ),"-G","0xF04","-l",str(MinReadLen),"-o",File4WGSDepth,"-@",str(NumOfThreads),"-b",str(File4DepthPanel),File4Bam)
	else:
		print("[ %s ] Begin depth info collect from wgs." % TimeStamp)
		pysam.depth("-q",str(MinBaseQ),"-Q",str(MinMapQ),"-G","0xF04","-l",str(MinReadLen),"-o",File4WGSDepth,"-@",str(NumOfThreads),File4Bam)
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	print("[ %s ] Depth info collection done." % TimeStamp)
	
	for i in range(len(File4BedS)):
		File4Bed = File4BedS[i]
		File4Log = File4LogS[i]
		
		# bed info all
		InfoToBedId = collections.defaultdict(int)
		DepthSum = []
		BedItemLen = []
		BedItem = []
		BedId = 0
		with open(File4Bed,"r") as BedH:
			Line = BedH.readline().strip('\n')
			while Line:
				Cols = Line.split('\t')
				BedId += 1
				DepthSum.append(0)
				BedItemLen.append(int(Cols[2]) - int(Cols[1]))
				BedItem.append('\t'.join(Cols[0:3]))
				for i in range(int(Cols[1]) + 1, int(Cols[2]) + 1, 1):
					StrKey = '\t'.join([Cols[0],str(i)])
					InfoToBedId[StrKey] = BedId
				Line = BedH.readline().strip('\n')
		TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
		print("[ %s ] Bed info collect done." % TimeStamp)
		
		# split by bed line id, into array
		with open(File4WGSDepth,"r") as DpH:
			Line = DpH.readline().strip('\n')
			while Line:
				Cols = Line.split('\t')
				StrKey = '\t'.join(Cols[0:2])
				if InfoToBedId[StrKey]:
					tId = InfoToBedId[StrKey] - 1
					DepthSum[tId] += int(Cols[2])
				Line = DpH.readline().strip('\n')
		TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
		print("[ %s ] Split by bed line done." % TimeStamp)
		
		# write
		FileH4Log = open(File4Log, "w")
		for i in range(len(BedItem)):
			MeanDepth = str("%.2f" % float(DepthSum[i] / BedItemLen[i]))
			Str = '\t'.join([BedItem[i], MeanDepth])
			FileH4Log.write(Str + '\n')
		FileH4Log.close()
	
	# clean env
	if IfFileExist(File4WGSDepth) and not Flag4TempSave:
		os.remove(File4WGSDepth)
		TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
		print("[ %s ] Environment clean." % TimeStamp)

def main():
	Descrip = '''
 Auther: zhangdong_xie@foxmail.com
 
 This script was used to calculate mean depth and read count (by another script) in bed area.
 
'''
	parser = MyParser(description=Descrip,formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('-b',metavar='Bam' , help='( Required ) Bam file.', required=True, dest='File4Bam', action='store')
	parser.add_argument('-r',metavar='Bed' , help='( Required ) Bed file (Could be multi times).', required=True, dest='File4BedS', action='append')
	parser.add_argument('-o',metavar='CoverageInfo', help='( Required ) File for logging coverage file (Could be multi times).', required=True, dest='File4LogS', action='append')
	parser.add_argument('-p',metavar='Bed4DepthArea', help='( Optional ) Bed for depth info collection.', required=False, dest='File4DepthPanel', action='store', default = "None")
	parser.add_argument('-t',metavar='NumberOfThreads', help='( Optional ) Number of threads (default: 4).', required=False, dest='NumOfThreads', action='store', type = int, default = "4")
	parser.add_argument('-q',metavar='MinBaseQ', help='( Optional ) Minimal base quality (default: 7).', required=False, dest='MinBaseQ', action='store', type = int, default = "7")
	parser.add_argument('-Q',metavar='MinMapQ', help='( Optional ) Minimal mapping quality (default: 20).', required=False, dest='MinMapQ', action='store', type = int, default = "20")
	parser.add_argument('-L',metavar='MinReadLength', help='( Optional ) Minimal read length (default: 200).', required=False, dest='MinReadLen', action='store', type = int, default = "200")
	parser.add_argument('-s',help='( Optional ) Flag for the save of temporary files (default: FALSE).', required=False, dest='Flag4TempSave', action='store_true')
	args = parser.parse_args()
	
	# -b, -r and -o must specified at least one;
	if not (args.File4Bam or args.File4BedS or args.File4LogS):
		print("Please specify -b, -r and -o\n%s" % Descrip)
		sys.exit(2)
	if len(args.File4BedS) != len(args.File4LogS):
		print("The number of -r and -o not equal.\n%s" % Descrip)
		sys.exit(2)
	
	# Time stamp
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	print("[ %s ] Script begins." % TimeStamp)
	print("[ Info ] Number of threads is %d" % args.NumOfThreads)
	
	# count
	BinCount(args.File4Bam, args.File4BedS, args.File4LogS, args.NumOfThreads, args.MinMapQ, args.MinBaseQ, args.MinReadLen, args.File4DepthPanel, args.Flag4TempSave)
	
	# Time stamp
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	print("[ %s ] Done" % TimeStamp)

if __name__ == '__main__':
	main()
