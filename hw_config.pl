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
