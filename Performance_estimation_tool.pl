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
my $Calculation;
my $sizeInputData;
my $sizeInputDataMin;
my $sizeOutputData;
my $sizeWeightData;
my $sizeWeightDataMin;
my $swWinograd;
#-------------------------------#

### Define of Results ###
my $sizeDRAMTraffic;
my $cycleDRAM;
my $cycleMAC;
my $cycleMAX;
my $pole;
#-------------------------------#
### Define of File ###
my $filenameInput = "mnist.json";
my $filenameOutput = "Result.csv";

my $command = '';
while(!$command){
	$command = shift;
	if($command eq '-f'){
		$command = shift;
		$filenameInput = $command;
	}elsif($command eq '-o'){
		$command = shift;
		$filenameOutput = $command;
	}else{
		print '[Error] Please follow format: perl /path/to/Performance_estimation_tool.pl -f /path/to/model.json -o /path/to/Result.csv';
		exit;
	}
}
print $filenameInput;

# Open files
open (FILEIN, $filenameInput);
open (FILEOUT, '>', $filenameOutput);

# Parameters
my $flag = "none";
my $tmp;
my $resultCnt = 0;

# Input
$numInputFeatureMapsC = $numInputFeatureMapsC0;
$lenInputHeightH = $lenInputHeightH0;
$lenInputWidthW = $lenInputWidthW0;

# Output result
print FILEOUT "Layer, Layer attribute, Layer name, #input feature maps(C), Input Height(H), Input Width(W), #output feature maps(K), Filter Height(R), Filter Width(S), Zero Padding(Z), Vertical Conv Srtide(H), Horizontal Conv Stride(V), Height after Conv(P), Width after Conv(Q), Pooling after Conv, Pooling Height(D), Pooling Width(E), Vertical pooling stride(F), Horizontal pooling stride(G), Height after Pooling(A), Height after Pooling(B), Calculation, Input data size, Output data size, Weight data size, DRAM Traffic, DRAM Cycles, MAC Cycles, MAX Cycle, Long Pole\n";

# Main loop for parsing
while ($record = <FILEIN>) {
   # print "$record\n";
   # Decider
   if($record =~ /"op": "(.*)"/i){
		$tmp = $1;
		if($1 =~ /conv/ || $1 =~ /pool/ || $1 =~ /dense/){
			$flag = $tmp;
			print "$tmp\n";
		}
   }elsif($record =~ /},/ && $flag =~ /^((?!none).)*$/){
		if($flag =~ /conv/ || $flag =~ /dense/){
			# Handle output
			if($resultCnt <= 1 && $resultCnt > 0){
				print FILEOUT ",,,,,,,";
			}
			if($resultCnt >= 1){
				$resultCnt = 0;
				# Mid Results of conv
				# Part of calculate by NVIDIA formula
				$sizeOutputData = ceil($lenHeightAfterPoolingA
									* $lenWidthAfterPoolingB
									* ceil($numOutputFeatureMapsK / 16.0)
									* 16.0
									* $byteInputData
									/ 1024.0);
									
				
				$sizeDRAMTraffic = $sizeInputData + $sizeOutputData + $sizeWeightData;
				$cycleDRAM = $sizeDRAMTraffic 
								/ $bwDRAM
								* $freq;
								
				if($cycleDRAM > $cycleMAC){
					$cycleMAX = $cycleDRAM;
					$pole = "DRAM";
				}else{
					$cycleMAX = $cycleMAC;
					$pole = "MAC";
				}

				#print FILEOUT "$Calculation, $sizeInputData\KB, $sizeInputDataMin\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeWeightDataMin\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
				print FILEOUT "$Calculation, $sizeInputData\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
				
				
			}
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
			
			if($attribute =~ /conv/){
				$attribute = "conv," . $attribute
			}
			if($attribute =~ /dense/){
				$attribute = "fc," . $attribute
			}
			print FILEOUT "\n$index, $attribute, $numInputFeatureMapsC, $lenInputHeightH, $lenInputWidthW, $numOutputFeatureMapsK, $lenFilterHeightR, $lenFilterWidthS, $swZeroPaddingZ, $lenVerticalConvStrideH, $lenHorizontalConvStrideV, $lenHeightAfter, $lenWidthAfter,";
			
			# Part of calculate by NVIDIA formula
			$Calculation = $numInputFeatureMapsC * $numOutputFeatureMapsK * $lenFilterHeightR * $lenFilterWidthS * $lenHeightAfterConvP * $lenWidthAfterConvQ;
			
			$sizeInputData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
									* 16.0 
									* ceil($lenInputHeightH / $lenVerticalConvStrideH)
									* ceil($lenInputWidthW / $lenHorizontalConvStrideV)
									* $byteInputData
									/ 1024.0);
			
			$sizeWeightData = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
									* 16.0
									* ceil($lenFilterHeightR / $lenVerticalConvStrideH)
									* ceil($lenFilterWidthS / $lenHorizontalConvStrideV)
									* $numOutputFeatureMapsK
									* $byteWeightData
									/ 1024.0);
									
			$cycleMAC = ceil(ceil($numInputFeatureMapsC * $lenVerticalConvStrideH * $lenHorizontalConvStrideV / 16.0)
							* 16.0
							* ceil($lenInputHeightH / $lenVerticalConvStrideH)
							* ceil($lenInputWidthW / $lenHorizontalConvStrideV)
							* ceil($numOutputFeatureMapsK / 16.0)
							* 16.0
							* $lenFilterHeightR
							* $lenFilterWidthS
							/ $lenVerticalConvStrideH
							/ $lenHorizontalConvStrideV
							/ $numMultiplier);
				
			
						
			
			# Assign activation(assign after output)
			$numInputFeatureMapsC = $chOutputFeatureMaps;
			$lenInputHeightH = $lenHeightAfter;
			$lenInputWidthW = $lenWidthAfter;
			
			
			
			$resultCnt++;
		}
		if($flag =~ /pool/){
			# Calculate activation
			$lenHeightAfter = ceil(($lenHeightAfter-$lenPoolingHeightD)/$lenVerticalPoolingStrideF);
			$lenWidthAfter = ceil(($lenWidthAfter-$lenPoolingWidthE)/$lenHorizontalPoolingStrideG);

			# Record
			$lenHeightAfterPoolingA = $lenHeightAfter;
			$lenWidthAfterPoolingB = $lenWidthAfter;
			
			print FILEOUT "$swPoolingConv, $lenPoolingHeightD, $lenPoolingWidthE, $lenVerticalPoolingStrideF, $lenHorizontalPoolingStrideG, $lenHeightAfter, $lenWidthAfter,";
				
			# Assign activation(assign after output)
			$numInputFeatureMapsC = $chOutputFeatureMaps;
			$lenInputHeightH = $lenHeightAfter;
			$lenInputWidthW = $lenWidthAfter;
			
			$resultCnt += 2;
		}

		$flag = "none";
		
		
   }else{
		if($flag =~ /conv/ || $flag =~ /pool/ || $flag =~ /dense/){
			
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

# Handle output
if($resultCnt <= 1 && $resultCnt > 0){
	print FILEOUT ",,,,,,,";
}
if($resultCnt >= 1){
	$resultCnt = 0;
	# Mid Results of conv
	# Part of calculate by NVIDIA formula
	
	
	

	$sizeOutputData = ceil($lenHeightAfterPoolingA
						* $lenWidthAfterPoolingB
						* ceil($numOutputFeatureMapsK / 16.0)
						* 16.0
						* $byteInputData
						/ 1024.0);
						
	
	$sizeDRAMTraffic = $sizeInputData + $sizeOutputData + $sizeWeightData;
	$cycleDRAM = $sizeDRAMTraffic 
					/ $bwDRAM
					* $freq;
					
	if($cycleDRAM > $cycleMAC){
		$cycleMAX = $cycleDRAM;
		$pole = "DRAM";
	}else{
		$cycleMAX = $cycleMAC;
		$pole = "MAC";
	}

	#print FILEOUT "$Calculation, $sizeInputData\KB, $sizeInputDataMin\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeWeightDataMin\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
	print FILEOUT "$Calculation, $sizeInputData\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
	
	
}

close(FILEIN);
close(FILEOUT); 
