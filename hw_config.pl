#!/usr/local/bin/perl
use strict;
use POSIX;
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


### Hardware config ###
# Type of data(Byte)
$byteInputData = 2;
$byteWeightData = 2;

# Size of convolution input buffer(KB)
$bufConvInput = 512;

# Number of Multiplier(16bit)
$numMultiplier = 1024;

# Frequency(MHz)
$freq = 1000;

# Bandwidth of memory(Gbps)
$bwSRAM = 25;
$bwDRAM = 10;

# Batch size of FC
$batchFc = 16;

### First input size ###
$numInputFeatureMapsC0 = 1;
$lenInputHeightH0 = 28;
$lenInputWidthW0 = 28;

### Other hardware config ###
# Compression
$ratioWeightCompression = 0.8;

# Convolution mode
$swWinogradConv = 0;
$swBatchedConv = 0;

# Switches of modules 
$swActivationEngine = 1;
$swBDMAEngine = 1;
$DataReshapeEngine = 0;
$PoolingEngine = 1;
$LRNEngine = 0;

# Buffer size of modules(KB)
$sizeActivationEngine = 32;
$sizePoolingEngine = 32;
$sizeLRNEngine = 32;

# Memory Read latency tolerance(us)
$maxMemoryReadLatency = 5;





