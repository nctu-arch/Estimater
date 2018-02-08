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
# Load
my %dataLoad;
# BDMA
my %confBDMA = (
);
# CDMA
my %confCDMA = (
	0xffff140a => 0x1000a, 		#NVDLA_CDMA.D_PIXEL_OFFSET_0
	0xffff141f => 0x50035400, 	#NVDLA_CDMA.D_WEIGHT_ADDR_LOW_0
	0xffff142d => 0x1010101, 	#NVDLA_CDMA.D_ZERO_PADDING_0
	0xffff1427 => 0x441097f1, 	#NVDLA_CDMA.D_MEAN_GLOBAL_0_0
	0xffff1412 => 0x1520, 		#NVDLA_CDMA.D_SURF_STRIDE_0
	0xffff1420 => 0x1b0000, 	#NVDLA_CDMA.D_WEIGHT_BYTES_0
	0xffff1408 => 0x17f, 		#NVDLA_CDMA.D_DATAIN_SIZE_1_0
	0xffff141c => 0xff, 		#NVDLA_CDMA.D_WEIGHT_SIZE_1_0
	0xffff142f => 0xb0003, 		#NVDLA_CDMA.D_BANK_0
	0xffff1430 => 0x1, 			#NVDLA_CDMA.D_NAN_FLUSH_TO_ZERO_0
	0xffff1407 => 0xc000c, 		#NVDLA_CDMA.D_DATAIN_SIZE_0_0
	0xffff140e => 0x85, 		#NVDLA_CDMA.D_DAIN_ADDR_HIGH_1_0
	0xffff1410 => 0x1a0, 		#NVDLA_CDMA.D_LINE_STRIDE_0
	0xffff1406 => 0x110e00, 	#NVDLA_CDMA.D_DATAIN_FORMAT_0
	0xffff1423 => 0x3e, 		#NVDLA_CDMA.D_WMB_ADDR_HIGH_0
	0xffff140d => 0x50015600, 	#NVDLA_CDMA.D_DAIN_ADDR_LOW_0_0
	0xffff1422 => 0xda70d100, 	#NVDLA_CDMA.D_WGS_ADDR_LOW_0
	0xffff1428 => 0xb4ef7ece, 	#NVDLA_CDMA.D_MEAN_GLOBAL_1_0
	0xffff1426 => 0x1, 			#NVDLA_CDMA.D_MEAN_FORMAT_0
	0xffff1409 => 0xc000c, 		#NVDLA_CDMA.D_DATAIN_SIZE_EXT_0_0
	0xffff1405 => 0x1001100, 	#NVDLA_CDMA.D_MISC_CFG_0
	0xffff1418 => 0x4d, 		#NVDLA_CDMA.D_ENTRY_PER_SLICE_0
	0xffff1411 => 0xecda72e0, 	#NVDLA_CDMA.D_LINE_UV_STRIDE_0
	0xffff140f => 0x8063e800, 	#NVDLA_CDMA.D_DAIN_ADDR_LOW_1_0
	0xffff141b => 0x1aff, 		#NVDLA_CDMA.D_WEIGHT_SIZE_0_0
	0xffff1424 => 0x5215c000, 	#NVDLA_CDMA.D_WMB_ADDR_LOW_0
	0xffff1413 => 0x10001, 		#NVDLA_CDMA.D_DAIN_MAP_0
	0xffff143a => 0x7841af46, 	#NVDLA_CDMA.D_CYA_0
	0xffff1417 => 0xef60180, 	#NVDLA_CDMA.D_BATCH_STRIDE_0
	0xffff1419 => 0xa, 			#NVDLA_CDMA.D_FETCH_GRAIN_0
	0xffff1414 => 0x36c0098, 	#NVDLA_CDMA.D_RESERVED_X_CFG_0
	0xffff1425 => 0x6a0180, 	#NVDLA_CDMA.D_WMB_BYTES_0
	0xffff1402 => 0x10001, 		#NVDLA_CDMA.S_ARBITER_0
	0xffff142b => 0x1, 			#NVDLA_CDMA.D_CVT_SCALE_0
	0xffff1415 => 0x110007, 	#NVDLA_CDMA.D_RESERVED_Y_CFG_0	
);
# CSC
my %confCSC = (
	0xffff1803 => 0x10001,		#NVDLA_CSC.D_ZERO_PADDING_0
	0xffff1815 => 0x1001100, 	#NVDLA_CSC.D_MISC_CFG_0
	0xffff180e => 0x6a0180,		#NVDLA_CSC.D_WMB_BYTES_0
	0xffff1805 => 0xc000c,		#NVDLA_CSC.D_DATAIN_SIZE_EXT_0_0
	0xffff180b => 0x20002,		#NVDLA_CSC.D_WEIGHT_SIZE_EXT_0_0
	0xffff1810 => 0xff,			#NVDLA_CSC.D_DATAOUT_SIZE_1_0
	0xffff1811 => 0xa8, 		#NVDLA_CSC.D_ATOMICS_0
	0xffff180c => 0xff017f,		#NVDLA_CSC.D_WEIGHT_SIZE_EXT_1_0
	0xffff1809 => 0x4d,			#NVDLA_CSC.D_ENTRY_PER_SLICE_0
	0xffff180f => 0xc000c, 		#NVDLA_CSC.D_DATAOUT_SIZE_0_0
	0xffff1818 => 0x1, 			#NVDLA_CSC.D_PRA_CFG_0
	0xffff1812 => 0x1, 			#NVDLA_CSC.D_RELEASE_0
	0xffff1806 => 0x17f, 		#NVDLA_CSC.D_DATAIN_SIZE_EXT_1_0
	0xffff1819 => 0x7841af46, 	#NVDLA_CSC.D_CYA_0
	0xffff1817 => 0xb0003, 		#NVDLA_CSC.D_BANK_0
	0xffff180d => 0x1b0000, 	#NVDLA_CSC.D_WEIGHT_BYTES_0
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
	0xffff2405 => 0xff, 		#NVDLA_CACC.D_DATAOUT_SIZE_1_0
	0xffff2403 => 0x1000, 		#NVDLA_CACC.D_MISC_CFG_0
	0xffff2406 => 0x1525f4a0, 	#NVDLA_CACC.D_DATAOUT_ADDR_0
	0xffff240d => 0x7841af46, 	#NVDLA_CACC.D_CYA_0
	0xffff2404 => 0xc000c, 		#NVDLA_CACC.D_DATAOUT_SIZE_0_0
	0xffff2408 => 0x2e0, 		#NVDLA_CACC.D_LINE_STRIDE_0
	0xffff2409 => 0x2640, 		#NVDLA_CACC.D_SURF_STRIDE_0
	0xffff240b => 0x3, 			#NVDLA_CACC.D_CLIP_CFG_0
);
# SDP_RDMA
my %confSDP_RDMA = (
);
# SDP
my %confSDP = (
	0xffff2c1e => 0x3100, 		#NVDLA_SDP.D_DP_BN_MUL_CFG_0
	0xffff2c1f => 0x3949, 		#NVDLA_SDP.D_DP_BN_MUL_SRC_VALUE_0
	0xffff2c21 => 0x2, 			#NVDLA_SDP.D_DP_EW_ALU_CFG_0
	0xffff2c22 => 0xd9f0, 		#NVDLA_SDP.D_DP_EW_ALU_SRC_VALUE_0
	0xffff2c19 => 0x1501, 		#NVDLA_SDP.D_DP_BS_MUL_CFG_0
	0xffff2c14 => 0x1a0, 		#NVDLA_SDP.D_DST_LINE_STRIDE_0
	0xffff2c23 => 0xb782acb7, 	#NVDLA_SDP.D_DP_EW_ALU_CVT_OFFSET_VALUE_0
	0xffff2c11 => 0xff, 		#NVDLA_SDP.D_DATA_CUBE_CHANNEL_0
	0xffff2c0f => 0xc, 			#NVDLA_SDP.D_DATA_CUBE_WIDTH_0
	0xffff2c17 => 0x1501, 		#NVDLA_SDP.D_DP_BS_ALU_CFG_0
	0xffff2c29 => 0x82f8, 		#NVDLA_SDP.D_DP_EW_MUL_CVT_SCALE_VALUE_0
	0xffff2c2a => 0x3e, 		#NVDLA_SDP.D_DP_EW_MUL_CVT_TRUNCATE_VALUE_0
	0xffff2c31 => 0x1, 			#NVDLA_SDP.D_CVT_SCALE_0
	0xffff2c18 => 0xa282, 		#NVDLA_SDP.D_DP_BS_ALU_SRC_VALUE_0
	0xffff2c28 => 0xc4b39a10, 	#NVDLA_SDP.D_DP_EW_MUL_CVT_OFFSET_VALUE_0
    0xffff2c1a => 0xec14,		#NVDLA_SDP.D_DP_BS_MUL_SRC_VALUE_0
    0xffff2c2b => 0x1c, 		#NVDLA_SDP.D_DP_EW_TRUNCATE_VALUE_0
    0xffff2c16 => 0x12, 		#NVDLA_SDP.D_DP_BS_CFG_0
    0xffff2c1d => 0x7fa8, 		#NVDLA_SDP.D_DP_BN_ALU_SRC_VALUE_0
    0xffff2c2f => 0x5, 			#NVDLA_SDP.D_DATA_FORMAT_0
    0xffff2c15 => 0x1520, 		#NVDLA_SDP.D_DST_SURFACE_STRIDE_0
    0xffff2c20 => 0x23, 		#NVDLA_SDP.D_DP_EW_CFG_0
    0xffff2c1b => 0x55, 		#NVDLA_SDP.D_DP_BN_CFG_0
    0xffff2c25 => 0x14, 		#NVDLA_SDP.D_DP_EW_ALU_CVT_TRUNCATE_VALUE_0
    0xffff2c2c => 0x1, 			#NVDLA_SDP.D_FEATURE_MODE_CFG_0
    0xffff2c26 => 0x3, 			#NVDLA_SDP.D_DP_EW_MUL_CFG_0
    0xffff2c12 => 0x50000020, 	#NVDLA_SDP.D_DST_BASE_ADDR_LOW_0
    0xffff2c2e => 0xb14aa80, 	#NVDLA_SDP.D_DST_BATCH_STRIDE_0
    0xffff2c37 => 0xc, 			#NVDLA_SDP.D_PERF_ENABLE_0
    0xffff2c27 => 0x5f248652, 	#NVDLA_SDP.D_DP_EW_MUL_SRC_VALUE_0
    0xffff2c10 => 0xc, 			#NVDLA_SDP.D_DATA_CUBE_HEIGHT_0
    0xffff2c1c => 0x1, 			#NVDLA_SDP.D_DP_BN_ALU_CFG_0
    0xffff2c24 => 0x780f, 		#NVDLA_SDP.D_DP_EW_ALU_CVT_SCALE_VALUE_0
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
    0xffff3002 => 0x1, 			#NVDLA_PDP_RDMA.D_OP_ENABLE_0
);
# PDP
my %confPDP = (
	0xffff3406 => 0x6, #NVDLA_PDP.D_DATA_CUBE_OUT_WIDTH_0
	0xffff340c => 0x701c07, #NVDLA_PDP.D_PARTIAL_WIDTH_OUT_0
	0xffff341b => 0x800, #NVDLA_PDP.D_SRC_SURFACE_STRIDE_0
	0xffff341a => 0x100, #NVDLA_PDP.D_SRC_LINE_STRIDE_0
	0xffff3407 => 0x6, #NVDLA_PDP.D_DATA_CUBE_OUT_HEIGHT_0
	0xffff340d => 0x101, #NVDLA_PDP.D_POOLING_KERNEL_CFG_0
	0xffff3408 => 0x3f, #NVDLA_PDP.D_DATA_CUBE_OUT_CHANNEL_0
	0xffff341e => 0xe0, #NVDLA_PDP.D_DST_LINE_STRIDE_0
	0xffff3421 => 0x101, #NVDLA_PDP.D_DATA_FORMAT_0
	0xffff3404 => 0x7, #NVDLA_PDP.D_DATA_CUBE_IN_HEIGHT_0
	0xffff340b => 0x701c07, #NVDLA_PDP.D_PARTIAL_WIDTH_IN_0
	0xffff3403 => 0x7, #NVDLA_PDP.D_DATA_CUBE_IN_WIDTH_0
	0xffff3409 => 0x11, #NVDLA_PDP.D_OPERATION_MODE_CFG_0
	0xffff341f => 0x620, #NVDLA_PDP.D_DST_SURFACE_STRIDE_0
	0xffff3420 => 0x1, #NVDLA_PDP.D_DST_RAM_CFG_0
	0xffff3405 => 0x3f, #NVDLA_PDP.D_DATA_CUBE_IN_CHANNEL_0
	0xffff3418 => 0x80000000, #NVDLA_PDP.D_SRC_BASE_ADDR_LOW_0
	0xffff341c => 0x80100000, #NVDLA_PDP.D_DST_BASE_ADDR_LOW_0
	0xffff3402 => 0x1, #NVDLA_PDP.D_OP_ENABLE_0
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

my $command = '';
while(!$command){
	$command = shift;
	if($command eq '-f'){
		$command = shift;
		$filenameInput = $command;
	}
	if($command eq '-o'){
		$command = shift;
		$filenameOutput = $command;
	}
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

			print FILEOUT "\n\n";
			### Generate (1)input feature map (2)weight instructions ###
			# Gen hash table of load data
			$tmpHex = sprintf("0x%x",$sizeInputData);
			$dataLoad{0x80000000} = hex($tmpHex);
			$tmpHex = sprintf("0x%x",$sizeWeightData);
			$dataLoad{0x80100000} = hex($tmpHex);
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


