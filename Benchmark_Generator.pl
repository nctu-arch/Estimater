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
my $SDP_RDMA_base = 0xffff280a;
my $SDP_RDMA_shift = 15;
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
my %enRBlock = (
	0xffff2802 => 0x00000001, #NVDLA_SDP_RDMA.D_OP_ENABLE_0disable
	0xffff2402 => 0x00000001, #NVDLA_CACC.D_OP_ENABLE_0
	0xffff1c02 => 0x00000001, #NVDLA_CMAC_A.D_OP_ENABLE_0
	0xffff2002 => 0x00000001, #NVDLA_CMAC_B.D_OP_ENABLE_0
	0xffff1802 => 0x00000001, #NVDLA_CSC.D_OP_ENABLE_0
	0xffff1404 => 0x00000001, #NVDLA_CDMA.D_OP_ENABLE_0
);
# Load
my %dataLoad;
# BDMA
my %confBDMA = (
);
# CDMA
my %confCDMA = (
	0xffff1401 => 0x0, #NVDLA_CDMA.S_POINTER_0CONSUMER: GROUP_0, PRODUCER: GROUP_0
	0xffff1402 => 0x3000f, #NVDLA_CDMA.S_ARBITER_0ARB_WEIGHT=15, ARB_WMB=3
	0xffff1405 => 0x11001100, #NVDLA_CDMA.D_MISC_CFG_0FULL_INPUT, FULL_WEIGHT, DIRECT, IN/OUT: INT16
	0xffff1406 => 0x0, #NVDLA_CDMA.D_DATAIN_FORMAT_0FEATURE DATA, PITCH LINEAR
	0xffff1407 => 0x70007, #NVDLA_CDMA.D_DATAIN_SIZE_0_08x8
	0xffff1408 => 0x1f, #NVDLA_CDMA.D_DATAIN_SIZE_1_0Channel: 32
	0xffff140a => 0x0, #NVDLA_CDMA.D_PIXEL_OFFSET_0
	0xffff140b => 0x1, #NVDLA_CDMA.D_DAIN_RAM_TYPE_0MC
	0xffff140c => 0x0, #NVDLA_CDMA.D_DAIN_ADDR_HIGH_0_0
	0xffff140d => 0x80000000, #NVDLA_CDMA.D_DAIN_ADDR_LOW_0_00MB
	0xffff140e => 0x0, #NVDLA_CDMA.D_DAIN_ADDR_HIGH_1_0
	0xffff140f => 0x0, #NVDLA_CDMA.D_DAIN_ADDR_LOW_1_0
	0xffff1410 => 0x100, #NVDLA_CDMA.D_LINE_STRIDE_0
	0xffff1412 => 0x800, #NVDLA_CDMA.D_SURF_STRIDE_0
	0xffff1413 => 0x10001, #NVDLA_CDMA.D_DAIN_MAP_0LINE_PACKED, SURF_PACKED
	0xffff1416 => 0x0, #NVDLA_CDMA.D_BATCH_NUMBER_0
	0xffff1417 => 0x0, #NVDLA_CDMA.D_BATCH_STRIDE_0
	0xffff1418 => 0x3, #NVDLA_CDMA.D_ENTRY_PER_SLICE_0
	0xffff1419 => 0x0, #NVDLA_CDMA.D_FETCH_GRAIN_0
	0xffff141a => 0x0, #NVDLA_CDMA.D_WEIGHT_FORMAT_0UNCOMPRESSED
	0xffff141b => 0xfff, #NVDLA_CDMA.D_WEIGHT_SIZE_0_00x1000-1
	0xffff141c => 0xf, #NVDLA_CDMA.D_WEIGHT_SIZE_1_0
	0xffff141d => 0x1, #NVDLA_CDMA.D_WEIGHT_RAM_TYPE_0MC
	0xffff141e => 0x0, #NVDLA_CDMA.D_WEIGHT_ADDR_HIGH_0
	0xffff141f => 0x80100000, #NVDLA_CDMA.D_WEIGHT_ADDR_LOW_01MB
	0xffff1420 => 0x10000, #NVDLA_CDMA.D_WEIGHT_BYTES_0
	0xffff1421 => 0x0, #NVDLA_CDMA.D_WGS_ADDR_HIGH_0
	0xffff1422 => 0x0, #NVDLA_CDMA.D_WGS_ADDR_LOW_0
	0xffff1425 => 0x0, #NVDLA_CDMA.D_WMB_BYTES_0
	0xffff1426 => 0x0, #NVDLA_CDMA.D_MEAN_FORMAT_0NONE
	0xffff1427 => 0x0, #NVDLA_CDMA.D_MEAN_GLOBAL_0_0
	0xffff1428 => 0x0, #NVDLA_CDMA.D_MEAN_GLOBAL_1_0
	0xffff1429 => 0x0, #NVDLA_CDMA.D_CVT_CFG_0DISABLE
	0xffff142a => 0x0, #NVDLA_CDMA.D_CVT_OFFSET_0
	0xffff142b => 0x0, #NVDLA_CDMA.D_CVT_SCALE_0
	0xffff142c => 0x0, #NVDLA_CDMA.D_CONV_STRIDE_0
	0xffff142d => 0x0, #NVDLA_CDMA.D_ZERO_PADDING_0
	0xffff142f => 0x20001, #NVDLA_CDMA.D_BANK_0 
	0xffff143a => 0x0, #NVDLA_CDMA.D_CYA_0
);
my %confRCDMA = (
	0xffff1401 => 0x00010001, #NVDLA_CDMA.S_POINTER_0CONSUMER: GROUP_0, PRODUCER: GROUP_0
	0xffff1402 => 0x000f000f, #NVDLA_CDMA.S_ARBITER_0ARB_WEIGHT=15, ARB_WMB=3
	0xffff1405 => 0x11113301, #NVDLA_CDMA.D_MISC_CFG_0FULL_INPUT, FULL_WEIGHT, DIRECT, IN/OUT: INT16
	0xffff1406 => 0x00113f01, #NVDLA_CDMA.D_DATAIN_FORMAT_0FEATURE DATA, PITCH LINEAR
	0xffff1407 => 0x1fff1fff, #NVDLA_CDMA.D_DATAIN_SIZE_0_08x8
	0xffff1408 => 0x00001fff, #NVDLA_CDMA.D_DATAIN_SIZE_1_0Channel: 32
	0xffff140a => 0x0007001f, #NVDLA_CDMA.D_PIXEL_OFFSET_0
	0xffff140b => 0x00000001, #NVDLA_CDMA.D_DAIN_RAM_TYPE_0MC
	0xffff140c => 0x000000ff, #NVDLA_CDMA.D_DAIN_ADDR_HIGH_0_0
	0xffff140d => 0xffffffe0, #NVDLA_CDMA.D_DAIN_ADDR_LOW_0_00MB
	0xffff140e => 0x000000ff, #NVDLA_CDMA.D_DAIN_ADDR_HIGH_1_0
	0xffff140f => 0xffffffe0, #NVDLA_CDMA.D_DAIN_ADDR_LOW_1_0
	0xffff1410 => 0xffffffe0, #NVDLA_CDMA.D_LINE_STRIDE_0
	0xffff1412 => 0xffffffe0, #NVDLA_CDMA.D_SURF_STRIDE_0
	0xffff1413 => 0x00010001, #NVDLA_CDMA.D_DAIN_MAP_0LINE_PACKED, SURF_PACKED
	0xffff1416 => 0x0000001f, #NVDLA_CDMA.D_BATCH_NUMBER_0
	0xffff1417 => 0xffffffe0, #NVDLA_CDMA.D_BATCH_STRIDE_0
	0xffff1418 => 0x00000fff, #NVDLA_CDMA.D_ENTRY_PER_SLICE_0
	0xffff1419 => 0x00000fff, #NVDLA_CDMA.D_FETCH_GRAIN_0
	0xffff141a => 0x00000001, #NVDLA_CDMA.D_WEIGHT_FORMAT_0UNCOMPRESSED
	0xffff141b => 0x0003ffff, #NVDLA_CDMA.D_WEIGHT_SIZE_0_00x1000-1
	0xffff141c => 0x00001fff, #NVDLA_CDMA.D_WEIGHT_SIZE_1_0
	0xffff141d => 0x00000001, #NVDLA_CDMA.D_WEIGHT_RAM_TYPE_0MC
	0xffff141e => 0x000000ff, #NVDLA_CDMA.D_WEIGHT_ADDR_HIGH_0
	0xffff141f => 0xffffffe0, #NVDLA_CDMA.D_WEIGHT_ADDR_LOW_01MB
	0xffff1420 => 0xffffff80, #NVDLA_CDMA.D_WEIGHT_BYTES_0
	0xffff1421 => 0x000000ff, #NVDLA_CDMA.D_WGS_ADDR_HIGH_0
	0xffff1422 => 0xffffffe0, #NVDLA_CDMA.D_WGS_ADDR_LOW_0
	0xffff1425 => 0x0fffff80, #NVDLA_CDMA.D_WMB_BYTES_0
	0xffff1426 => 0x00000001, #NVDLA_CDMA.D_MEAN_FORMAT_0NONE
	0xffff1427 => 0xffffffff, #NVDLA_CDMA.D_MEAN_GLOBAL_0_0
	0xffff1428 => 0xffffffff, #NVDLA_CDMA.D_MEAN_GLOBAL_1_0
	0xffff1429 => 0x000003f1, #NVDLA_CDMA.D_CVT_CFG_0DISABLE
	0xffff142a => 0x0000ffff, #NVDLA_CDMA.D_CVT_OFFSET_0
	0xffff142b => 0x0000ffff, #NVDLA_CDMA.D_CVT_SCALE_0
	0xffff142c => 0x00070007, #NVDLA_CDMA.D_CONV_STRIDE_0
	0xffff142d => 0x3f1f3f1f, #NVDLA_CDMA.D_ZERO_PADDING_0
	0xffff142f => 0x000f000f, #NVDLA_CDMA.D_BANK_0
	0xffff143a => 0xffffffff, #NVDLA_CDMA.D_CYA_0
);
# CSC
my %confCSC = (
	0xffff1801 => 0x0, #NVDLA_CSC.S_POINTER_0
	0xffff1803 => 0x11001100, #NVDLA_CSC.D_MISC_CFG_0DIRECT, IN/OUT: INT16
	0xffff1804 => 0x0, #NVDLA_CSC.D_DATAIN_FORMAT_0FEATURE DATA, PITCH LINEAR
	0xffff1805 => 0x70007, #NVDLA_CSC.D_DATAIN_SIZE_EXT_0_08x8
	0xffff1806 => 0x1f, #NVDLA_CSC.D_DATAIN_SIZE_EXT_1_0channel: 32
	0xffff1807 => 0x0, #NVDLA_CSC.D_BATCH_NUMBER_0
	0xffff1809 => 0x3, #NVDLA_CSC.D_ENTRY_PER_SLICE_0
	0xffff180a => 0x0, #NVDLA_CSC.D_WEIGHT_FORMAT_0
	0xffff180b => 0x70007, #NVDLA_CSC.D_WEIGHT_SIZE_EXT_0_0
	0xffff180c => 0xf001f, #NVDLA_CSC.D_WEIGHT_SIZE_EXT_1_0
	0xffff180d => 0x10000, #NVDLA_CSC.D_WEIGHT_BYTES_0
	0xffff180e => 0x0, #NVDLA_CSC.D_WMB_BYTES_0
	0xffff180f => 0x0, #NVDLA_CSC.D_DATAOUT_SIZE_0_0
	0xffff1810 => 0xf, #NVDLA_CSC.D_DATAOUT_SIZE_1_0
	0xffff1811 => 0x0, #NVDLA_CSC.D_ATOMICS_0
	0xffff1813 => 0x0, #NVDLA_CSC.D_CONV_STRIDE_EXT_0
	0xffff1814 => 0x0, #NVDLA_CSC.D_DILATION_EXT_0
	0xffff1815 => 0x0, #NVDLA_CSC.D_ZERO_PADDING_0
	0xffff1816 => 0x0, #NVDLA_CSC.D_ZERO_PADDING_VALUE_0
	0xffff1817 => 0x20001, #NVDLA_CSC.D_BANK_0
	0xffff1819 => 0x0, #NVDLA_CSC.D_CYA_0
);
my %confRCSC = (
	0xffff1801 => 0x00010001, #NVDLA_CSC.S_POINTER_0
	0xffff1803 => 0x11113301, #NVDLA_CSC.D_MISC_CFG_0DIRECT, IN/OUT: INT16
	0xffff1804 => 0x00000001, #NVDLA_CSC.D_DATAIN_FORMAT_0FEATURE DATA, PITCH LINEAR
	0xffff1805 => 0x1fff1fff, #NVDLA_CSC.D_DATAIN_SIZE_EXT_0_08x8
	0xffff1806 => 0x00001fff, #NVDLA_CSC.D_DATAIN_SIZE_EXT_1_0channel: 32
	0xffff1807 => 0x0000001f, #NVDLA_CSC.D_BATCH_NUMBER_0
	0xffff1809 => 0x00000fff, #NVDLA_CSC.D_ENTRY_PER_SLICE_0
	0xffff180a => 0x00000001, #NVDLA_CSC.D_WEIGHT_FORMAT_0
	0xffff180b => 0x001f001f, #NVDLA_CSC.D_WEIGHT_SIZE_EXT_0_0
	0xffff180c => 0x1fff1fff, #NVDLA_CSC.D_WEIGHT_SIZE_EXT_1_0
	0xffff180d => 0xffffff80, #NVDLA_CSC.D_WEIGHT_BYTES_0
	0xffff180e => 0x0fffff80, #NVDLA_CSC.D_WMB_BYTES_0
	0xffff180f => 0x1fff1fff, #NVDLA_CSC.D_DATAOUT_SIZE_0_0
	0xffff1810 => 0x00001fff, #NVDLA_CSC.D_DATAOUT_SIZE_1_0
	0xffff1811 => 0x001fffff, #NVDLA_CSC.D_ATOMICS_0
	0xffff1813 => 0x00070007, #NVDLA_CSC.D_CONV_STRIDE_EXT_0
	0xffff1814 => 0x001f001f, #NVDLA_CSC.D_DILATION_EXT_0
	0xffff1815 => 0x001f001f, #NVDLA_CSC.D_ZERO_PADDING_0
	0xffff1816 => 0x0000ffff, #NVDLA_CSC.D_ZERO_PADDING_VALUE_0
	0xffff1817 => 0x000f000f, #NVDLA_CSC.D_BANK_0
	0xffff1819 => 0xffffffff, #NVDLA_CSC.D_CYA_0
);
# CMAC_A
my %confCMAC_A = (
	0xffff1c01 => 0x0, #NVDLA_CMAC_A.S_POINTER_0
	0xffff1c03 => 0x1000, #NVDLA_CMAC_A.D_MISC_CFG_0
);
my %confRCMAC_A = (
	0xffff1c01 => 0x00010001, #NVDLA_CMAC_A.S_POINTER_0
	0xffff1c03 => 0x00003001, #NVDLA_CMAC_A.D_MISC_CFG_0
);
# CMAC_B
my %confCMAC_B = (
	0xffff2001 => 0x0, #NVDLA_CMAC_B.S_POINTER_0
	0xffff2003 => 0x1000, #NVDLA_CMAC_B.D_MISC_CFG_0
);
my %confRCMAC_B = (
	0xffff2001 => 0x00010001, #NVDLA_CMAC_B.S_POINTER_0
	0xffff2003 => 0x00003001, #NVDLA_CMAC_B.D_MISC_CFG_0
);
# CACC
my %confCACC = (
	0xffff2401 => 0x0, #NVDLA_CACC.S_POINTER_0
	0xffff2403 => 0x1000, #NVDLA_CACC.D_MISC_CFG_0
	0xffff2404 => 0x0, #NVDLA_CACC.D_DATAOUT_SIZE_0_0
	0xffff2405 => 0xf, #NVDLA_CACC.D_DATAOUT_SIZE_1_0
	0xffff2406 => 0x80400000, #NVDLA_CACC.D_DATAOUT_ADDR_0
	0xffff2407 => 0x0, #NVDLA_CACC.D_BATCH_NUMBER_0
	0xffff2408 => 0x20, #NVDLA_CACC.D_LINE_STRIDE_0
	0xffff2409 => 0x20, #NVDLA_CACC.D_SURF_STRIDE_0
	0xffff240a => 0x10001, #NVDLA_CACC.D_DATAOUT_MAP_0Line_packed, surf_packed
	0xffff240b => 0x0, #NVDLA_CACC.D_CLIP_CFG_0
	0xffff240d => 0x0, #NVDLA_CACC.D_CYA_0
);
my %confRCACC = (
	0xffff2401 => 0x00010001, #NVDLA_CACC.S_POINTER_0
	0xffff2403 => 0x00003001, #NVDLA_CACC.D_MISC_CFG_0
	0xffff2404 => 0x1fff1fff, #NVDLA_CACC.D_DATAOUT_SIZE_0_0
	0xffff2405 => 0x00001fff, #NVDLA_CACC.D_DATAOUT_SIZE_1_0
	0xffff2406 => 0xffffffe0, #NVDLA_CACC.D_DATAOUT_ADDR_0
	0xffff2407 => 0x0000001f, #NVDLA_CACC.D_BATCH_NUMBER_0
	0xffff2408 => 0x00ffffe0, #NVDLA_CACC.D_LINE_STRIDE_0
	0xffff2409 => 0x00ffffe0, #NVDLA_CACC.D_SURF_STRIDE_0
	0xffff240a => 0x00010001, #NVDLA_CACC.D_DATAOUT_MAP_0Line_packed, surf_packed
	0xffff240b => 0x0000001f, #NVDLA_CACC.D_CLIP_CFG_0
	0xffff240d => 0xffffffff, #NVDLA_CACC.D_CYA_0
);
# SDP_RDMA
my %confSDP_RDMA = (
	0xffff2810 => 0x1b, 		#NVDLA_SDP_RDMA.D_NRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff2816 => 0x1b, 		#NVDLA_SDP_RDMA.D_ERDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff280a => 0x1b, 		#NVDLA_SDP_RDMA.D_BRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
);
my %confRSDP_RDMA = (
	0xffff2810 => 0x0000003f, #NVDLA_SDP_RDMA.D_NRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff2816 => 0x0000003f, #NVDLA_SDP_RDMA.D_ERDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
	0xffff280a => 0x0000003f, #NVDLA_SDP_RDMA.D_BRDMA_CFG_0BRDMA_DATA_MODE=PER_ELEMENT, BRDMA_DATA_SIZE=TWO_BYTE, BRDMA_DATA_USE=ALU, BRDMA_DISABLE=YES
);
# SDP
my %confSDP = (
	0xffff2c01 => 0x0, #NVDLA_SDP.S_POINTER_0
	0xffff2c02 => 0x0, #NVDLA_SDP.S_LUT_ACCESS_CFG_0
	0xffff2c03 => 0x0, #NVDLA_SDP.S_LUT_ACCESS_DATA_0
	0xffff2c04 => 0x0, #NVDLA_SDP.S_LUT_CFG_0
	0xffff2c0f => 0x0, #NVDLA_SDP.D_DATA_CUBE_WIDTH_0
	0xffff2c10 => 0x0, #NVDLA_SDP.D_DATA_CUBE_HEIGHT_0
	0xffff2c11 => 0xf, #NVDLA_SDP.D_DATA_CUBE_CHANNEL_0
	0xffff2c12 => 0x80400000, #NVDLA_SDP.D_DST_BASE_ADDR_LOW_04MB
	0xffff2c13 => 0x0, #NVDLA_SDP.D_DST_BASE_ADDR_HIGH_0
	0xffff2c14 => 0x20, #NVDLA_SDP.D_DST_LINE_STRIDE_0
	0xffff2c15 => 0x20, #NVDLA_SDP.D_DST_SURFACE_STRIDE_01*1*32B
	0xffff2c16 => 0x1a, #NVDLA_SDP.D_DP_BS_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c17 => 0x2, #NVDLA_SDP.D_DP_BS_ALU_CFG_0SHIFT RIGHT, SHIFT_VALUE=0, SRC=REG
	0xffff2c18 => 0x0, #NVDLA_SDP.D_DP_BS_ALU_SRC_VALUE_0
	0xffff2c19 => 0x0, #NVDLA_SDP.D_DP_BS_MUL_CFG_0SHIFT_VALUE=16, SRC=REG
	0xffff2c1a => 0x1, #NVDLA_SDP.D_DP_BS_MUL_SRC_VALUE_0
	0xffff2c2c => 0x1, #NVDLA_SDP.D_FEATURE_MODE_CFG_0FLYING_MODE=ON, OUTPUT_DST=MEM, WINOGRAD=OFF, BATCH_NUMBER=0
	0xffff2c1b => 0x1, #NVDLA_SDP.D_DP_BN_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c20 => 0x1, #NVDLA_SDP.D_DP_EW_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c2d => 0x1, #NVDLA_SDP.D_DST_DMA_CFG_0MC
	0xffff2c2e => 0x0, #NVDLA_SDP.D_DST_BATCH_STRIDE_0
	0xffff2c2f => 0x5, #NVDLA_SDP.D_DATA_FORMAT_0INPUT_DATA=INT16, OUTPUT_DATA=INT16
	0xffff2c30 => 0x0, #NVDLA_SDP.D_CVT_OFFSET_0
	0xffff2c31 => 0x1, #NVDLA_SDP.D_CVT_SCALE_0SCALE=1 to make all data not change in SDP
	0xffff2c32 => 0x0, #NVDLA_SDP.D_CVT_SHIFT_0
);
my %confRSDP = (
	0xffff2c01 => 0x00010001, #NVDLA_SDP.S_POINTER_0
	0xffff2c02 => 0x000303ff, #NVDLA_SDP.S_LUT_ACCESS_CFG_0
	0xffff2c03 => 0x0000ffff, #NVDLA_SDP.S_LUT_ACCESS_DATA_0
	0xffff2c04 => 0x00000071, #NVDLA_SDP.S_LUT_CFG_0
	0xffff2c0f => 0x00001fff, #NVDLA_SDP.D_DATA_CUBE_WIDTH_0
	0xffff2c10 => 0x00001fff, #NVDLA_SDP.D_DATA_CUBE_HEIGHT_0
	0xffff2c11 => 0x00001fff, #NVDLA_SDP.D_DATA_CUBE_CHANNEL_0
	0xffff2c12 => 0xffffffe0, #NVDLA_SDP.D_DST_BASE_ADDR_LOW_04MB
	0xffff2c13 => 0x000000ff, #NVDLA_SDP.D_DST_BASE_ADDR_HIGH_0
	0xffff2c14 => 0xffffffe0, #NVDLA_SDP.D_DST_LINE_STRIDE_0
	0xffff2c15 => 0xffffffe0, #NVDLA_SDP.D_DST_SURFACE_STRIDE_01*1*32B
	0xffff2c16 => 0x0000007f, #NVDLA_SDP.D_DP_BS_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c17 => 0x00003f01, #NVDLA_SDP.D_DP_BS_ALU_CFG_0SHIFT RIGHT, SHIFT_VALUE=0, SRC=REG
	0xffff2c18 => 0x0000ffff, #NVDLA_SDP.D_DP_BS_ALU_SRC_VALUE_0
	0xffff2c19 => 0x0000ff01, #NVDLA_SDP.D_DP_BS_MUL_CFG_0SHIFT_VALUE=16, SRC=REG
	0xffff2c1a => 0x0000ffff, #NVDLA_SDP.D_DP_BS_MUL_SRC_VALUE_0
	0xffff2c2c => 0x00001f0f, #NVDLA_SDP.D_FEATURE_MODE_CFG_0FLYING_MODE=ON, OUTPUT_DST=MEM, WINOGRAD=OFF, BATCH_NUMBER=0
	0xffff2c1b => 0x0000007f, #NVDLA_SDP.D_DP_BN_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c20 => 0x0000007f, #NVDLA_SDP.D_DP_EW_CFG_0BS_BYPASS=NO, BS_ALU_BYPASS=YES, BS_ALU_ALGO=SUM, BS_MUL_BYPASS=YES, BS_RELU_BYPASS=NO
	0xffff2c2d => 0x00000001, #NVDLA_SDP.D_DST_DMA_CFG_0MC
	0xffff2c2e => 0xffffffe0, #NVDLA_SDP.D_DST_BATCH_STRIDE_0
	0xffff2c2f => 0x0000000f, #NVDLA_SDP.D_DATA_FORMAT_0INPUT_DATA=INT16, OUTPUT_DATA=INT16
	0xffff2c30 => 0xffffffff, #NVDLA_SDP.D_CVT_OFFSET_0
	0xffff2c31 => 0x0000ffff, #NVDLA_SDP.D_CVT_SCALE_0SCALE=1 to make all data not change in SDP
	0xffff2c32 => 0x0000003f, #NVDLA_SDP.D_CVT_SHIFT_0
	0xffff2c0e => 0x00000001, #NVDLA_SDP.D_OP_ENABLE_0
);
# PDP_RDMA-
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
# PDP-
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
			# print FILEOUT "$op $tmpBase 0x0\n";
		}else{
			$tmpVal = sprintf("0x%x", $hashTable{$base});
			print FILEOUT "$op $tmpBase $tmpVal\n";
		}
		$base++;
	}
}
sub printInstrwr{
	local($base, $shift, $hashTable, $hashTable_check) = @_;
	local $tmpBase, $tmpVal, $tmpVal_r;
	for(;$shift>=0;$shift--){
		$tmpBase = sprintf("0x%x", $base);
		if($hashTable->{$base} == undef){
			#print FILEOUT "$op $tmpBase 0x0\n";
			if($hashTable_check->{$base} == undef){
				
			}else{
				$tmpVal_r = sprintf("0x%x", $hashTable_check->{$base});
				print FILEOUT "write_reg $tmpBase 0x0\nread_reg $tmpBase $tmpVal_r 0x0\n";
			}
		}else{
			$tmpVal = sprintf("0x%x", $hashTable->{$base});
			$tmpVal_r = sprintf("0x%x", $hashTable_check->{$base});
			print FILEOUT "write_reg $tmpBase $tmpVal\nread_reg $tmpBase $tmpVal_r $tmpVal\n";
			#print FILEOUT "";
		}
		$base++;
	}
}
# sub printInstrwr{
	# local($base, $shift, %hashTablew, %hashTabler) = @_;
	# # write
	# #printInstr('write_reg', $base, $shift, %hashTablew);
	# # read
	# printInstrr($base, $shift, %hashTablew, %hashTabler);
# }
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

my $swInputPara = 0;
my $filenameOutput_feature_map = "input_feature_map1.dat";
my $filenameOutput_weight = "input_weight1.dat";


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

open (FILEOUT_feature_map, '>', $filenameOutput_feature_map);
open (FILEOUT_weight, '>', $filenameOutput_weight);

# Parameters
my $flag = "none";
my $tmp;
my $resultCnt = 0;
my $hexTemp;

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
			if($swZeroPaddingZ eq "FALSE"){
				$lenHeightAfter = ceil(($lenInputHeightH-$lenFilterHeightR)/$lenVerticalConvStrideH)+1;
				$lenWidthAfter = ceil(($lenInputWidthW-$lenFilterWidthS)/$lenHorizontalConvStrideV)+1;
			}else{
				$lenHeightAfter = ceil($lenInputHeightH/$lenVerticalConvStrideH);
				$lenWidthAfter = ceil($lenInputWidthW/$lenHorizontalConvStrideV);
			}
			# Record
			$lenHeightAfterConvP = $lenHeightAfter;
			$lenWidthAfterConvQ = $lenWidthAfter;
			# Assign output feature map, show # of Output Feature Maps(K)
			$numOutputFeatureMapsK = $chOutputFeatureMaps;
			
			# $sizeInputData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
			# 						* 16.0 
			# 						* ceil($lenInputHeightH / $lenVerticalConvStrideH)
			# 						* ceil($lenInputWidthW / $lenHorizontalConvStrideV)
			# 						* $byteInputData);
			
			$sizeInputData = $numInputFeatureMapsC * $lenInputHeightH * $lenInputWidthW * $byteInputData;
			
			# $sizeWeightData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
			# 						* 16.0
			# 						* ceil($lenFilterHeightR / $lenVerticalConvStrideH)
			# 						* ceil($lenFilterWidthS / $lenHorizontalConvStrideV)
			# 						* $numOutputFeatureMapsK
			# 						* $byteWeightData);
			
			$sizeWeightData = $numInputFeatureMapsC * $lenFilterHeightR * $lenFilterWidthS * $numOutputFeatureMapsK * $byteWeightData;
			
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
			$enBlock{$SDP_EN} = 0x1;
			$enBlock{$SDP_RDMA_EN} = 0x0;
			$enBlock{$CACC_EN} = 0x1;
			$enBlock{$CMAC_A_EN} = 0x1;
			$enBlock{$CMAC_B_EN} = 0x1;
			$enBlock{$CSC_EN} = 0x1;
			$enBlock{$CDMA_EN} = 0x1;
			#printInstr('write_reg', $CDMA_EN, 0, %enBlock);
			#printInstr('write_reg', $CSC_EN, 0, %enBlock);
			#printInstr('write_reg', $CACC_EN, 0, %enBlock);
			#printInstr('write_reg', $SDP_EN, 0, %enBlock);
			printInstrwr($SDP_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($SDP_RDMA_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($CACC_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($CMAC_A_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($CMAC_B_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($CSC_EN, 0, \%enBlock, \%enRBlock);
			printInstrwr($CDMA_EN, 0, \%enBlock, \%enRBlock);
					
			print FILEOUT "\n\n";
			### Generate (1)input feature map (2)weight instructions ###
			# Gen hash table of load data
			$dataLoad{0x80000000} = $sizeInputData;
			$dataLoad{0x80100000} = $sizeWeightData;
			printInstr('load_mem', 0x80000000, 0, %dataLoad);
			printInstr('load_mem', 0x80100000, 0, %dataLoad);
			
			### Generate conv and dense instructions ###
			# BDMA
			#printInstrwr($BDMA_base, $BDMA_shift, %confBDMA,  %confRBDMA);
			# CDMA
			printInstrwr($CDMA_base, $CDMA_shift, \%confCDMA, \%confRCDMA);
			# CSC
			printInstrwr($CSC_base, $CSC_shift, \%confCSC, \%confRCSC);
			# CMAC_A
			printInstrwr($CMAC_A_base, $CMAC_A_shift, \%confCMAC_A, \%confRCMAC_A);
			# CMAC_B
			printInstrwr($CMAC_B_base, $CMAC_B_shift, \%confCMAC_B, \%confRCMAC_B);
			# CACC
			printInstrwr($CACC_base, $CACC_shift, \%confCACC, \%confRCACC);
			

			### Generate input ###
			if($swInputPara == 3){
				$swInputPara=100;
				# Feature Map
				$hexTemp = sprintf("0x%x", $sizeInputData);
				print FILEOUT_feature_map "Data_size = $hexTemp\n";
				print FILEOUT_feature_map "Data_type = 0x25\n";
				print FILEOUT_feature_map "Kernel_num=$numOutputFeatureMapsK\n";
				print FILEOUT_feature_map "W = $lenInputWidthW\n";
				print FILEOUT_feature_map "H = $lenInputHeightH\n";
				print FILEOUT_feature_map "C = $numInputFeatureMapsC\n";
				$hexTemp = sprintf("0x%x", $lenInputHeightH * 0x20);
				print FILEOUT_feature_map "Line_stride = $hexTemp\n";
				$hexTemp = sprintf("0x%x", $lenInputHeightH * $lenInputWidthW * 0x20);
				print FILEOUT_feature_map "Surface_stride = $hexTemp\n";
				print FILEOUT_feature_map "Precision = INT16\n";
				# gen
				for (my $i=0; $i < $sizeInputData; $i++) {
					$hexTemp = sprintf("0x%02x", int(rand(256)));
					print FILEOUT_feature_map "$hexTemp ";
					if($i != 0 and ($i+1)%32==0){
						print FILEOUT_feature_map "\n";
					}
				}
				
				# Weight
				$hexTemp = sprintf("0x%x", $lenFilterHeightR);
				print FILEOUT_weight "W=$hexTemp\n";
				$hexTemp = sprintf("0x%x", $lenFilterWidthS);
				print FILEOUT_weight "H=$hexTemp\n";
				$hexTemp = sprintf("0x%x", $numInputFeatureMapsC);
				print FILEOUT_weight "C=$hexTemp\n";
				print FILEOUT_weight "Data_type=0x2\n";
				$hexTemp = sprintf("0x%x", $numOutputFeatureMapsK);
				print FILEOUT_weight "Kernel_num=$hexTemp\n";
				print FILEOUT_weight "Precision=INT16\n";
				$hexTemp = sprintf("0x%x", $sizeWeightData);
				print FILEOUT_weight "Data_size=$hexTemp\n";
				# gen
				for (my $i=0; $i < $sizeWeightData; $i++) {
					$hexTemp = sprintf("0x%02x", int(rand(256)));
					print FILEOUT_weight "$hexTemp ";
					if($i != 0 and ($i+1)%32==0){
						print FILEOUT_weight "\n";
					}
				}
			}else{
				$swInputPara++;
			}
			
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
			printInstrwr($SDP_RDMA_base, $SDP_RDMA_shift, \%confSDP_RDMA, \%confRSDP_RDMA);
			# SDP
			printInstrwr($SDP_base, $SDP_shift, \%confSDP, \%confRSDP);
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
		$lenFilterHeightR = $lenInputHeightH;
		$lenFilterWidthS = $lenInputWidthW;
		$swZeroPaddingZ = "FALSE";
		$lenVerticalConvStrideH = 1;
		$lenHorizontalConvStrideV = 1;
   }
}

close(FILEIN);
close(FILEOUT);
close(FILEOUT_feature_map);
close(FILEOUT_weight);


