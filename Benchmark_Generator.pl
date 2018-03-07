#!/usr/local/bin/perl
#use strict;
use POSIX;

### Hardware config(Set from "hw_config.pl" file) ###
require './hw_config.pl';
our $byteInputData;
our $byteWeightData;
our $bufConvInput;
our $numMultiplier;
our $freq;
our $bwSRAM;
our $bwDRAM;
our $batchFc;
our $numInputFeatureMapsC0;
our $lenInputHeightH0;
our $lenInputWidthW0;

our $ratioWeightCompression;
our $swWinogradConv;
our $swBatchedConv;
our $swActivationEngine;
our $swBDMAEngine;
our $DataReshapeEngine;
our $PoolingEngine;
our $LRNEngine;
our $sizeActivationEngine;
our $sizePoolingEngine;
our $sizeLRNEngine;
our $maxMemoryReadLatency;

#-------------------------------#
### Define of HW Module Config Address ###
my $GLB_base = 0x0;
my $GLB_shift = 0;
my $MCIF_base = 0x0;
my $MCIF_shift = 0;
my $SRAMIF_base = 0x0;
my $SRAMIF_shift = 0;
my $BDMA_base = 0xffff1001;
my $BDMA_shift = 12;
my $CDMA_base = 0xffff1401;
my $CDMA_shift = 57;
my $CSC_base = 0xffff1801;
my $CSC_shift = 24;
my $CMAC_A_base = 0xffff1c01;
my $CMAC_A_shift = 2;
my $CMAC_B_base = 0xffff2001;
my $CMAC_B_shift = 2;
my $CACC_base = 0xffff2401;
my $CACC_shift = 12;
my $SDP_RDMA_base = 0xffff2810;
my $SDP_RDMA_shift = 9;
my $SDP_base = 0xffff2c01;
my $SDP_shift = 13;
my $PDP_RDMA_base = 0xffff3001;
my $PDP_RDMA_shift = 15;
my $PDP_base = 0xffff3401;
my $PDP_shift = 32;
my $CDP_RDMA_base = 0x0;
my $CDP_RDMA_shift = 0;
my $CDP_base = 0x0;
my $CDP_shift = 0;
my $RUBIK_base = 0x0;
my $RUBIK_shift = 0;

### Define of HW Module ENABLE Address ###
my $MCIF_EN = 0x0;
my $SRAMIF_EN = 0x0;
my $BDMA_EN = 0xffff100d;
my $CDMA_EN = 0xffff1404;
my $CSC_EN = 0xffff1802;
my $CMAC_A_EN = 0xffff1c02;
my $CMAC_B_EN = 0xffff2002;
my $CACC_EN = 0xffff2402;
my $SDP_RDMA_EN = 0xffff2802;
my $SDP_EN = 0xffff2c0e;
my $PDP_RDMA_EN = 0xffff3002;
my $PDP_EN = 0xffff3402;
my $CDP_RDMA_EN = 0x0;
my $CDP_EN = 0x0;
my $RUBIK_EN = 0x0;

### Default config hash ###
# ENABLE
my %enBlock;
# Load
my %dataLoad;
# BDMA
my %confBDMA = (
);
# CDMA
my %confCDMA = (	
	0xffff1402 => 0x3000f, 		#NVDLA_CDMA.S_ARBITER_0ARB_WEIGHT=15, ARB_WMB=3
	0xffff1405 => 0x11001100, 	#NVDLA_CDMA.D_MISC_CFG_0FULL_INPUT, FULL_WEIGHT, DIRECT, IN/OUT: INT16
	0xffff1407 => 0x70007, 		#NVDLA_CDMA.D_DATAIN_SIZE_0_08x8
	0xffff1408 => 0x1f, 		#NVDLA_CDMA.D_DATAIN_SIZE_1_0Channel: 32
	0xffff140b => 0x1, 			#NVDLA_CDMA.D_DAIN_RAM_TYPE_0MC
	0xffff140d => 0x80000000, 	#NVDLA_CDMA.D_DAIN_ADDR_LOW_0_00MB
	0xffff1410 => 0x100, 		#NVDLA_CDMA.D_LINE_STRIDE_0
	0xffff1412 => 0x800, 		#NVDLA_CDMA.D_SURF_STRIDE_0
	0xffff1413 => 0x10001, 		#NVDLA_CDMA.D_DAIN_MAP_0LINE_PACKED, SURF_PACKED
	0xffff1418 => 0x3, 			#NVDLA_CDMA.D_ENTRY_PER_SLICE_0
	0xffff141b => 0xfff, 		#NVDLA_CDMA.D_WEIGHT_SIZE_0_00x1000-1
	0xffff141c => 0xf, 			#NVDLA_CDMA.D_WEIGHT_SIZE_1_0
	0xffff141d => 0x1, 			#NVDLA_CDMA.D_WEIGHT_RAM_TYPE_0MC
	0xffff141f => 0x80100000, 	#NVDLA_CDMA.D_WEIGHT_ADDR_LOW_01MB
	0xffff1420 => 0x10000, 		#NVDLA_CDMA.D_WEIGHT_BYTES_0
	0xffff142f => 0x20001, 		#NVDLA_CDMA.D_BANK_0
);
# CSC
my %confCSC = (
	0xffff1803 => 0x11001100, 	#NVDLA_CSC.D_MISC_CFG_0DIRECT, IN/OUT: INT16
	0xffff1805 => 0x70007, 		#NVDLA_CSC.D_DATAIN_SIZE_EXT_0_08x8
	0xffff1806 => 0x1f, 		#NVDLA_CSC.D_DATAIN_SIZE_EXT_1_0channel: 32
	0xffff1809 => 0x3, 			#NVDLA_CSC.D_ENTRY_PER_SLICE_0
	0xffff180b => 0x70007, 		#NVDLA_CSC.D_WEIGHT_SIZE_EXT_0_0
	0xffff180c => 0xf001f, 		#NVDLA_CSC.D_WEIGHT_SIZE_EXT_1_0
	0xffff180d => 0x10000, 		#NVDLA_CSC.D_WEIGHT_BYTES_0
	0xffff180f => 0x0, 			#NVDLA_CSC.D_DATAOUT_SIZE_0_0
	0xffff1810 => 0xf, 			#NVDLA_CSC.D_DATAOUT_SIZE_1_0
	0xffff1817 => 0x20001, 		#NVDLA_CSC.D_BANK_0
);
# CMAC_A
my %confCMAC_A = (
	0xffff1c03 => 0x1000, 		#NVDLA_CMAC_A.D_MISC_CFG_0
);
# CMAC_B
my %confCMAC_B = (
	0xffff2003 => 0x1000,	 	#NVDLA_CMAC_B.D_MISC_CFG_0
);
# CACC
my %confCACC = (
	0xffff2403 => 0x1000, 		#NVDLA_CACC.D_MISC_CFG_0
	0xffff2404 => 0x0, 			#NVDLA_CACC.D_DATAOUT_SIZE_0_0
	0xffff2405 => 0xf, 			#NVDLA_CACC.D_DATAOUT_SIZE_1_0
	0xffff2406 => 0x80400000, 	#NVDLA_CACC.D_DATAOUT_ADDR_0
	0xffff2408 => 0x20, 		#NVDLA_CACC.D_LINE_STRIDE_0
	0xffff2409 => 0x20, 		#NVDLA_CACC.D_SURF_STRIDE_0
	0xffff240a => 0x10001, 		#NVDLA_CACC.D_DATAOUT_MAP_0Line_packed, surf_packed
);
# SDP_RDMA
my %confSDP_RDMA = (
	0xffff2810 => 0x1b, 		#NVDLA_SDP_RDMA.D_NRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff2816 => 0x1b, 		#NVDLA_SDP_RDMA.D_ERDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff280a => 0x1b, 		#NVDLA_SDP_RDMA.D_BRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
);
# SDP
my %confSDP = (
	0xffff2c11 => 0xf, 			#NVDLA_SDP.D_DATA_CUBE_CHANNEL_0
	0xffff2c12 => 0x80400000, 	#NVDLA_SDP.D_DST_BASE_ADDR_LOW_04MB
	0xffff2c14 => 0x20, 		#NVDLA_SDP.D_DST_LINE_STRIDE_0
	0xffff2c15 => 0x20, 		#NVDLA_SDP.D_DST_SURFACE_STRIDE_01*1*32B
	0xffff2c16 => 0x1a, 		#NVDLA_SDP.D_DP_BS_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c17 => 0x2, 			#NVDLA_SDP.D_DP_BS_ALU_CFG_0SHIFT RIGHT, SHIFT_VALUE=0, SRC=REG
	0xffff2c1a => 0x1, 			#NVDLA_SDP.D_DP_BS_MUL_SRC_VALUE_0
	0xffff2c2c => 0x1, 			#NVDLA_SDP.D_FEATURE_MODE_CFG_0FLYING_MODE=ON, OUTPUT_DST=MEM, WINOGRAD=OFF, BATCH_NUMBER=0
	0xffff2c1b => 0x1, 			#NVDLA_SDP.D_DP_BN_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c20 => 0x1, 			#NVDLA_SDP.D_DP_EW_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c2d => 0x1, 			#NVDLA_SDP.D_DST_DMA_CFG_0MC
	0xffff2c2f => 0x5, 			#NVDLA_SDP.D_DATA_FORMAT_0INPUT_DATA=INT16, OUTPUT_DATA=INT16
	0xffff2c31 => 0x1, 			#NVDLA_SDP.D_CVT_SCALE_0SCALE=1 to make all data not change in SDP
);
# PDP_RDMA
my %confPDP_RDMA = (
	0xffff300a => 0x800, 		#NVDLA_PDP_RDMA.D_SRC_SURFACE_STRIDE_0
    0xffff3009 => 0x100, 		#NVDLA_PDP_RDMA.D_SRC_LINE_STRIDE_0
    0xffff300e => 0x1, 			#NVDLA_PDP_RDMA.D_POOLING_KERNEL_CFG_0
    0xffff300c => 0x101, 		#NVDLA_PDP_RDMA.D_DATA_FORMAT_0
    0xffff3004 => 0x7, 			#NVDLA_PDP_RDMA.D_DATA_CUBE_IN_HEIGHT_0
    0xffff3010 => 0x701c07, 	#NVDLA_PDP_RDMA.D_PARTIAL_WIDTH_IN_0
    0xffff3003 => 0x7, 			#NVDLA_PDP_RDMA.D_DATA_CUBE_IN_WIDTH_0
    0xffff300b => 0x1, 			#NVDLA_PDP_RDMA.D_SRC_RAM_CFG_0
    0xffff3006 => 0x1, 			#NVDLA_PDP_RDMA.D_FLYING_MODE_0
    0xffff3007 => 0x80000000, 	#NVDLA_PDP_RDMA.D_SRC_BASE_ADDR_LOW_0
    0xffff3005 => 0x3f, 		#NVDLA_PDP_RDMA.D_DATA_CUBE_IN_CHANNEL_0
);
# PDP
my %confPDP = (
	0xffff3406 => 0x6, 			#NVDLA_PDP.D_DATA_CUBE_OUT_WIDTH_0
	0xffff340c => 0x701c07, 	#NVDLA_PDP.D_PARTIAL_WIDTH_OUT_0
	0xffff341b => 0x800, 		#NVDLA_PDP.D_SRC_SURFACE_STRIDE_0
	0xffff341a => 0x100, 		#NVDLA_PDP.D_SRC_LINE_STRIDE_0
	0xffff3407 => 0x6, 			#NVDLA_PDP.D_DATA_CUBE_OUT_HEIGHT_0
	0xffff340d => 0x101, 		#NVDLA_PDP.D_POOLING_KERNEL_CFG_0
	0xffff3408 => 0x3f, 		#NVDLA_PDP.D_DATA_CUBE_OUT_CHANNEL_0
	0xffff341e => 0xe0, 		#NVDLA_PDP.D_DST_LINE_STRIDE_0
	0xffff3421 => 0x101, 		#NVDLA_PDP.D_DATA_FORMAT_0
	0xffff3404 => 0x7, 			#NVDLA_PDP.D_DATA_CUBE_IN_HEIGHT_0
	0xffff340b => 0x701c07, 	#NVDLA_PDP.D_PARTIAL_WIDTH_IN_0
	0xffff3403 => 0x7, 			#NVDLA_PDP.D_DATA_CUBE_IN_WIDTH_0
	0xffff3409 => 0x11, 		#NVDLA_PDP.D_OPERATION_MODE_CFG_0
	0xffff341f => 0x620, 		#NVDLA_PDP.D_DST_SURFACE_STRIDE_0
	0xffff3420 => 0x1, 			#NVDLA_PDP.D_DST_RAM_CFG_0
	0xffff3405 => 0x3f, 		#NVDLA_PDP.D_DATA_CUBE_IN_CHANNEL_0
	0xffff3418 => 0x80000000, 	#NVDLA_PDP.D_SRC_BASE_ADDR_LOW_0
	0xffff341c => 0x80100000, 	#NVDLA_PDP.D_DST_BASE_ADDR_LOW_0
);

### Print instructions ###
sub printInstr{
	local($op, $base, $shift, %hashTable) = @_;
	local $tmpBase, $tmpVal;
	for(;$shift>=0;$shift--){
		$tmpBase = sprintf("0x%x", $base);
		if($hashTable{$base} == undef){
			print FILEOUT "$op $tmpBase 0x0\n";
		}else{
			$tmpVal = sprintf("0x%x", $hashTable{$base});
			print FILEOUT "$op $tmpBase $tmpVal\n";
		}
		$base++;
	}
}

#-------------------------------#

### Define of Parameters of layer ###
my $index = 0;
my $attribute;

my $numInputFeatureMapsC = $numInputFeatureMapsC0;
my $lenInputHeightH = $lenInputHeightH0;
my $lenInputWidthW = $lenInputWidthW0;
my $numOutputFeatureMapsK;
my $lenFilterHeightR;
my $lenFilterWidthS;
my $swZeroPaddingZ;
my $lenVerticalConvStrideH = 9999;
my $lenHorizontalConvStrideV = 9999;

my $lenHeightAfterConvP;
my $lenWidthAfterConvQ;

my $swPoolingConv;
my $lenPoolingHeightD;
my $lenPoolingWidthE;
my $lenVerticalPoolingStrideF = 9999;
my $lenHorizontalPoolingStrideG = 9999;

my $lenHeightAfterPoolingA;
my $lenWidthAfterPoolingB;

# Activation
my $chOutputFeatureMaps;
my $lenHeightAfter;
my $lenWidthAfter;

#-------------------------------#
### Define of Mid Results ###
my $sizeInputData;
my $sizeWeightData;

#-------------------------------#
### Define of File ###
my $filenameInput = "mnist.json";
my $filenameOutput = "input.txn";

my $command = shift;
while($command ne ""){
	if($command eq '-f'){
		$command = shift;
		$filenameInput = $command;
	}
	if($command eq '-o'){
		$command = shift;
		$filenameOutput = $command;
	}
	$command = shift;
}

# Open files
open (FILEIN, $filenameInput);
open (FILEOUT, '>', $filenameOutput);

# Parameters
my $flag = "none";
my $tmp;
my $resultCnt = 0;
my $tmpHex;

# Input
$numInputFeatureMapsC = $numInputFeatureMapsC0;
$lenInputHeightH = $lenInputHeightH0;
$lenInputWidthW = $lenInputWidthW0;
	
# Main loop for parsing
while ($record = <FILEIN>) {
   # print "$record\n";
   # Decider
   if($record =~ /"op": "(.*)"/i){
		$tmp = $1;
		if($1 =~ /conv/ || $1 =~ /pool/ || $1 =~ /dense/ || $1 =~ /relu/){
			$flag = $tmp;
			print "$tmp\n";
		}
   }elsif($record =~ /},/ && $flag =~ /^((?!none).)*$/){
		if($flag =~ /conv/ || $flag =~ /dense/){
			# Calculate num of layer
			$index++;$swPoolingConv="TRUE";
			# Calculate activation
			$lenHeightAfter = ceil($lenInputHeightH/$lenVerticalConvStrideH);
			$lenWidthAfter = ceil($lenInputWidthW/$lenHorizontalConvStrideV);
			# Record
			$lenHeightAfterConvP = $lenHeightAfter;
			$lenWidthAfterConvQ = $lenWidthAfter;
			# Assign output feature map, show # of Output Feature Maps(K)
			$numOutputFeatureMapsK = $chOutputFeatureMaps;
			
			$sizeInputData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
									* 16.0 
									* ceil($lenInputHeightH / $lenVerticalConvStrideH)
									* ceil($lenInputWidthW / $lenHorizontalConvStrideV)
									* $byteInputData);
			
			$sizeWeightData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
									* 16.0
									* ceil($lenFilterHeightR / $lenVerticalConvStrideH)
									* ceil($lenFilterWidthS / $lenHorizontalConvStrideV)
									* $numOutputFeatureMapsK
									* $byteWeightData);

			
			### Assign value of configure ###
			# CDMA
			$confCDMA{0xffff1407} = ($lenInputHeightH-0x1) * 0x10000 + ($lenInputWidthW-0x1); #NVDLA_CDMA.D_DATAIN_SIZE_0_08x8
			#print  sprintf("0x%x",$confCDMA{0xffff1407});
			$confCDMA{0xffff1408} = $numInputFeatureMapsC - 0x1; #NVDLA_CDMA.D_DATAIN_SIZE_1_0Channel: 32
			$confCDMA{0xffff1410} = $lenInputHeightH * 0x20; #NVDLA_CDMA.D_LINE_STRIDE_0
			$confCDMA{0xffff1412} = $lenInputHeightH * $lenInputWidthW * 0x20; #NVDLA_CDMA.D_SURF_STRIDE_0
			$confCDMA{0xffff141b} = ceil($sizeWeightData/$numOutputFeatureMapsK) - 0x1; #NVDLA_CDMA.D_WEIGHT_SIZE_0_00x1000-1
			$confCDMA{0xffff141c} = $numOutputFeatureMapsK; #NVDLA_CDMA.D_WEIGHT_SIZE_1_0
			$confCDMA{0xffff1420} = $sizeWeightData; #NVDLA_CDMA.D_WEIGHT_BYTES_0
			# CSC
			$confCSC{0xffff1805} = ($lenInputHeightH-0x1) * 0x10000 + ($lenInputWidthW-0x1); #NVDLA_CSC.D_DATAIN_SIZE_EXT_0_08x8
			$confCSC{0xffff1806} = $numInputFeatureMapsC - 0x1; #NVDLA_CSC.D_DATAIN_SIZE_EXT_1_0channel: 32
			$confCSC{0xffff180b} = ($lenInputHeightH-0x1) * 0x10000 + ($lenInputWidthW-0x1); #NVDLA_CSC.D_WEIGHT_SIZE_EXT_0_0
			$confCSC{0xffff180c} = $numOutputFeatureMapsK * 0x10000 + ($numInputFeatureMapsC - 0x1); #NVDLA_CSC.D_WEIGHT_SIZE_EXT_1_0
			$confCSC{0xffff180d} = $sizeWeightData; #NVDLA_CSC.D_WEIGHT_BYTES_0
			$confCSC{0xffff180f} = ($lenHeightAfterConvP-0x1) * 0x10000 + ($lenWidthAfterConvQ-0x1); #NVDLA_CSC.D_DATAOUT_SIZE_0_0
			$confCSC{0xffff1810} = $numOutputFeatureMapsK; #NVDLA_CSC.D_DATAOUT_SIZE_1_0
			# CACC
			$confCACC{0xffff2404} = ($lenHeightAfterConvP-0x1) * 0x10000 + ($lenWidthAfterConvQ-0x1); #NVDLA_CACC.D_DATAOUT_SIZE_0_0
			$confCACC{0xffff2405} = $numOutputFeatureMapsK; #NVDLA_CACC.D_DATAOUT_SIZE_1_0
			$confCACC{0xffff2408} = $lenHeightAfterConvP * 0x20; #NVDLA_CACC.D_LINE_STRIDE_0
			$confCACC{0xffff2409} = $lenHeightAfterConvP * $lenWidthAfterConvQ * 0x20; #NVDLA_CACC.D_SURF_STRIDE_0
			# SDP
			$confSDP{0xffff2c11} = $numOutputFeatureMapsK; #NVDLA_SDP.D_DATA_CUBE_CHANNEL_0
			$confSDP{0xffff2c14} = $lenHeightAfterConvP * 0x20; #NVDLA_SDP.D_DST_LINE_STRIDE_0
			$confSDP{0xffff2c15} = $lenHeightAfterConvP * $lenWidthAfterConvQ * 0x20; #NVDLA_SDP.D_DST_SURFACE_STRIDE_01*1*32B
			# SDP_RDMA
			# PDP
			
			# PDP_RDMA

			# ENABLE
			$enBlock{$CDMA_EN} = 0x1;
			$enBlock{$CSC_EN} = 0x1;
			$enBlock{$CACC_EN} = 0x1;
			$enBlock{$SDP_EN} = 0x1;
			printInstr('write_reg', $CDMA_EN, 0, %enBlock);
			printInstr('write_reg', $CSC_EN, 0, %enBlock);
			printInstr('write_reg', $CACC_EN, 0, %enBlock);
			printInstr('write_reg', $SDP_EN, 0, %enBlock);
			
			print FILEOUT "\n\n";
			### Generate (1)input feature map (2)weight instructions ###
			# Gen hash table of load data
			$dataLoad{0x80000000} = $sizeInputData;
			$dataLoad{0x80100000} = $sizeWeightData;
			printInstr('load_mem', 0x80000000, 0, %dataLoad);
			printInstr('load_mem', 0x80100000, 0, %dataLoad);
			
			### Generate conv and dense instructions ###
			# BDMA
			printInstr('write_reg', $BDMA_base, $BDMA_shift, %confBDMA);
			# CDMA
			printInstr('write_reg', $CDMA_base, $CDMA_shift, %confCDMA);
			# CSC
			printInstr('write_reg', $CSC_base, $CSC_shift, %confCSC);
			# CMAC_A
			printInstr('write_reg', $CMAC_A_base, $CMAC_A_shift, %confCMAC_A);
			# CMAC_B
			printInstr('write_reg', $CMAC_B_base, $CMAC_B_shift, %confCMAC_B);
			# CACC
			printInstr('write_reg', $CACC_base, $CACC_shift, %confCACC);
						
			# Assign activation(assign after output)
			$numInputFeatureMapsC = $chOutputFeatureMaps;
			$lenInputHeightH = $lenHeightAfter;
			$lenInputWidthW = $lenWidthAfter;

			$resultCnt++;
		}
		if($flag =~ /relu/){
			$resultCnt += 2;
			
			### Generate relu instructions
			# SDP_RDMA
			printInstr('write_reg', $SDP_RDMA_base, $SDP_RDMA_shift, %confSDP_RDMA);
			# SDP
			printInstr('write_reg', $SDP_base, $SDP_shift, %confSDP);
			print FILEOUT "";
		}
		if($flag =~ /pool/){
			# Calculate activation
			$lenHeightAfter = ceil(($lenHeightAfter-$lenPoolingHeightD)/$lenVerticalPoolingStrideF);
			$lenWidthAfter = ceil(($lenWidthAfter-$lenPoolingWidthE)/$lenHorizontalPoolingStrideG);

			# Record
			$lenHeightAfterPoolingA = $lenHeightAfter;
			$lenWidthAfterPoolingB = $lenWidthAfter;
		
			# Assign activation(assign after output)
			$numInputFeatureMapsC = $chOutputFeatureMaps;
			$lenInputHeightH = $lenHeightAfter;
			$lenInputWidthW = $lenWidthAfter;
			
			$resultCnt += 4;
			
			### Generate pool instructions
			# PDP_RDMA
			printInstr('write_reg', $PDP_RDMA_base, $PDP_RDMA_shift, %confPDP_RDMA);
			# PDP
			printInstr('write_reg', $PDP_base, $PDP_shift, %confPDP);
			print FILEOUT "";
		}
		$flag = "none";
		
		
   }else{
		if($flag =~ /conv/ || $flag =~ /pool/ || $flag =~ /dense/ || $flag =~ /relu/){
			
		}else{
			next;
		}
   }

   # Check convolution
   if($flag =~ /conv/){
		if($record =~ /"(.*)": "(.*)"/i){
			$tmp = $2;
			if($1 =~ /name/){
				$attribute = $tmp;
				print "$tmp\n";
			}
			if($1 =~ /channels/){
				$chOutputFeatureMaps = $tmp;
				print "$tmp\n";
			}
			if($1 =~ /kernel_size/){
				if($tmp =~ /\[(\d+)L, (\d+)L\]/i){
					$lenFilterHeightR = $1;
					$lenFilterWidthS = $2;
					print "$tmp, lenFilterHeightR = $1, lenFilterWidthS = $2\n";
				}
			}
			if($1 =~ /padding/){
				$swZeroPaddingZ = "TRUE";
			}
			if($1 =~ /strides/){
				if($tmp =~ /\[(\d+)L, (\d+)L\]/i){
					$lenVerticalConvStrideH = $1;
					$lenHorizontalConvStrideV = $2;
					print "$tmp, lenVerticalConvStrideH = $1, lenHorizontalConvStrideV = $2\n";
				}
			}
		}
   }
   # Check relu
   if($flag =~ /conv/){
		if($record =~ /"(.*)": "(.*)"/i){
			$tmp = $2;
			if($1 =~ /name/){
				$attribute = $tmp;
				print "$tmp\n";
			}
		}
   }
   # Check pooling
   if($flag =~ /pool/){
		if($record =~ /"(.*)": "(.*)"/i){
			$tmp = $2;
			if($1 =~ /name/){
				$attribute = $tmp;
				print "$tmp\n";
			}
			if($1 =~ /padding/){
				# Do nothing
			}
			if($1 =~ /pool_size/){
				if($tmp =~ /\[(\d+)L, (\d+)L\]/i){
					$lenPoolingHeightD = $1;
					$lenPoolingWidthE = $2;
					print "$tmp, lenPoolingHeightD = $1, lenPoolingWidthE = $2\n";
				}
			}
			if($1 =~ /strides/){
				if($tmp =~ /\[(\d+)L, (\d+)L\]/i){
					$lenVerticalPoolingStrideF = $1;
					$lenHorizontalPoolingStrideG = $2;
					print "$tmp, lenVerticalPoolingStrideF = $1, lenHorizontalPoolingStrideG = $2\n";
				}
			}
		}
   }
   # Check fully connected
   if($flag =~ /dense/){
		if($record =~ /"(.*)": "(.*)"/i){
			$tmp = $2;
			if($1 =~ /name/){
				$attribute = $tmp;
				print "$tmp\n";
			}
			if($1 =~ /units/){
				$chOutputFeatureMaps = $tmp;
				print "$tmp\n";
			}
			if($1 =~ /use_bias/){
				# Do nothing
			}
		}
		$lenFilterHeightR = 1;
		$lenFilterWidthS = 1;
		$swZeroPaddingZ = "TRUE";
		$lenVerticalConvStrideH = 1;
		$lenHorizontalConvStrideV = 1;
   }
}

close(FILEIN);
close(FILEOUT); 


