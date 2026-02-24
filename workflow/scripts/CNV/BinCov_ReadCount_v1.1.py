#!/usr/bin/python
import argparse
import pysam
import time
import sys
import os
import numpy as np


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

def BinCount(File4Bam, File4Bed, File4Log, NumOfThreads, MinMapQ, MinBaseQ, MinReadLen):
	# Open file
	SamFile = pysam.AlignmentFile(File4Bam, mode = "rb", threads = NumOfThreads)
	FileH4Log = open(File4Log, "w")
	
	# Process
	NumOfProcessed = 0
	StartTime = time.time()
	with open(File4Bed,"r") as fb:
		for item in fb:
			Area = item.strip().split('\t')
			Chr = str(Area[0])
			Start = int(Area[1])
			End = int(Area[2])
			Tag4Area= Area[0] + ":" + Area[1] + "-" + Area[2]
			
			# mean depth by count_coverage (no mapping quality)
			#DepthSum = SamFile.count_coverage(Chr, Start, End, quality_threshold = MinBaseQ, min_mapping_quality = MinMapQ, read_callback = 'all')
			#MeanDepth = (sum(DepthSum[0]) + sum(DepthSum[1]) + sum(DepthSum[2]) + sum(DepthSum[3])) / (int(Area[2]) - int(Area[1]) + 1)
			#MeanDepth = str("%.2f" % MeanDepth)
			
			# samtools coverage
			#DepthInfo = pysam.depth("-a","-r",Tag4Area,"-q",str(MinBaseQ),"-Q",str(MinMapQ),"-G","0xF04",File4Bam).strip('\n').split('\n')
			#Depths = [ float(str(x).split('\t')[2]) for x in DepthInfo ]
			#MeanDepth = sum(Depths) / len(Depths)
			#MeanDepth = str("%.2f" % MeanDepth)
			
			# read count by count
			#ReadCount = SamFile.count(Chr, Start, End, read_callback = 'all')
			
			# read count by fetch, but same id only count once
			AllReads = SamFile.fetch(Chr, Start, End)
			ReadStr = []
			for read in AllReads :
				# not read.is_proper_pair only in NGS, fail for ONT
				if read.is_duplicate or read.is_qcfail or read.is_secondary or read.is_supplementary or read.is_unmapped or read.mate_is_unmapped:
					continue
				if read.query_length < MinReadLen or read.mapping_quality < MinMapQ :
					continue
				ReadStr.append(read.query_name)
			values, counts = np.unique(ReadStr, return_counts=True)
			ReadCount = str(len(values))
			
			# Log
			FileH4Log.write('\t'.join([Chr, str(Start), str(End), ReadCount]) + '\n')
			
			NumOfProcessed += 1
			if NumOfProcessed % 10000 == 0 :
				TimeConsume = Second2String(time.time() - StartTime)
				print("[ %s ] Processed %d" % (TimeConsume, NumOfProcessed))
				StartTime = time.time()

	SamFile.close()
	FileH4Log.close()

def main():
	Descrip = '''
 Auther: zhangdong_xie@foxmail.com
 
 This script was used to calculate mean depth (discarded) and read count in bed area.
 
'''
	parser = MyParser(description=Descrip,formatter_class=argparse.RawDescriptionHelpFormatter)
	parser.add_argument('-b',metavar='Bam' , help='( Required ) Bam file.', required=True, dest='File4Bam', action='store')
	parser.add_argument('-r',metavar='Bed' , help='( Required ) Bed file.', required=True, dest='File4Bed', action='store')
	parser.add_argument('-o',metavar='CoverageInfo', help='( Required ) File for logging coverage file.', required=True, dest='File4Log', action='store')
	parser.add_argument('-t',metavar='NumberOfThreads', help='( Optional ) Number of threads (default: 4).', required=False, dest='NumOfThreads', action='store', type = int, default = "4")
	parser.add_argument('-q',metavar='MinBaseQ', help='( Optional ) Minimal base quality (default: 7).', required=False, dest='MinBaseQ', action='store', type = int, default = "7")
	parser.add_argument('-Q',metavar='MinMapQ', help='( Optional ) Minimal mapping quality (default: 20).', required=False, dest='MinMapQ', action='store', type = int, default = "20")
	parser.add_argument('-L',metavar='MinReadLength', help='( Optional ) Minimal read length (default: 200).', required=False, dest='MinReadLen', action='store', type = int, default = "200")
	args = parser.parse_args()
	
	# -b, -r and -o must specified at least one;
	if not (args.File4Bam or args.File4Bed or args.File4Log):
		print("Please specify -b, -r and -o\n%s" % Descrip)
		sys.exit(2)
	
	# Time stamp
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	print("[ %s ] Script begins." % TimeStamp)
	print("[ Info ] Number of threads is %d" % args.NumOfThreads)
	
	# count
	BinCount(args.File4Bam, args.File4Bed, args.File4Log, args.NumOfThreads, args.MinMapQ, args.MinBaseQ, args.MinReadLen)
	
	# Time stamp
	TimeStamp = time.strftime("%Y/%m/%d %H:%M:%S", time.localtime())
	print("[ %s ] Done" % TimeStamp)

if __name__ == '__main__':
	main()