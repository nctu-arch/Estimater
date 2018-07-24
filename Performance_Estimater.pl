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
### Define of list ###
my $nodeManager;

### Define of printing model ###
my $model;
my $modelIndex = 0;

#-------------------------------#
### Define of File ###
my $filenameInput = "mobilenet.json";
my $filenameOutput = "Result.csv";



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
	# else{
		# print '[Error] Please follow format: perl /path/to/Performance_estimation_tool.pl -f /path/to/model.json -o /path/to/Result.csv';
		# exit;
	# }
	$command = shift;
}

# Open files
open (FILEIN, $filenameInput);
open (FILEOUT, '>', $filenameOutput);

# Parameters
my $flag = "none";
my $tmp;

# Input
my $startBit = 1;

# Output result
print FILEOUT "Layer, Layer attribute, Layer name, #input feature maps(C), Input Height(H), Input Width(W), #output feature maps(K), Filter Height(R), Filter Width(S), Zero Padding(Z), Vertical Conv Srtide(H), Horizontal Conv Stride(V), Height after Conv(P), Width after Conv(Q), Pooling after Conv, Pooling Height(D), Pooling Width(E), Vertical pooling stride(F), Horizontal pooling stride(G), Height after Pooling(A), Height after Pooling(B), Calculation, Input data size, Output data size, Weight data size, DRAM Traffic, DRAM Cycles, MAC Cycles, MAX Cycle, Long Pole\n";

# Main loop for parsing
while ($record = <FILEIN>) {
   # print "$record\n";
   # Decider
   if($record =~ /"op": "(.*)"/i){
		$tmp = $1;
		if($1 =~ /null/){ #/conv|pool|dense|batch|dense/
			
		}else{
			$flag = $tmp;
			print "- $tmp\n";
		}
		
   }elsif($flag =~ /^((?!none).)*$/ && $record =~ /"inputs": \[(.*)\]/i){
		$tmp = $1;
		if($flag =~ /conv/ || $flag =~ /dense/){
			
			# Parse number of nodes -> "inputs"  
			my $match;
			if(@match=($tmp =~ /\[(\d+), \d+, \d+\]/ig)){
				print "- conv&dense node: ";
				for $i(0..$#match){
					print "$match[$i] "
				}
				print "\n";
			}
			
			# Find previous number of nodes
			if($startBit == 1){
				$startBit = 0;
				$numInputFeatureMapsC = $numInputFeatureMapsC0;
				$lenInputHeightH = $lenInputHeightH0;
				$lenInputWidthW = $lenInputWidthW0;				
			}else{
				if($nodeManager[$match[0]-1]{takeBit} == 1){
					$numInputFeatureMapsC = $nodeManager[$match[0]-1]{chOutputFeatureMaps};
					$lenInputHeightH = $nodeManager[$match[0]-1]{lenHeightAfter};
					$lenInputWidthW = $nodeManager[$match[0]-1]{lenWidthAfter};
				}
			}
			
			if($flag =~/dense/){
				$lenFilterHeightR = $lenInputHeightH;
				$lenFilterWidthS = $lenInputWidthW;
			}
			
			# Calculate num of layer
			$index++;
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
			
			# Assign output feature map to number of node(model list)
			# print "- conv&dense nodes: $1, $2, $3\n"				
			$nodeManager[$match[$#match]]{chOutputFeatureMaps} = $chOutputFeatureMaps;
			$nodeManager[$match[$#match]]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$match[$#match]]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$match[$#match]]{takeBit} = 1;
			

			if($attribute =~ /conv/){
				$attribute = "conv," . $attribute
			}
			if($attribute =~ /dense/){
				$attribute = "fc," . $attribute
			}
			#print FILEOUT "\n$index, $attribute, $numInputFeatureMapsC, $lenInputHeightH, $lenInputWidthW, $numOutputFeatureMapsK, $lenFilterHeightR, $lenFilterWidthS, $swZeroPaddingZ, $lenVerticalConvStrideH, $lenHorizontalConvStrideV, $lenHeightAfter, $lenWidthAfter,";

			#print FILEOUT "$Calculation, $sizeInputData\KB, $sizeInputDataMin\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeWeightDataMin\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
			#print FILEOUT "$Calculation, $sizeInputData\KB, $sizeOutputData\KB, $sizeWeightData\KB, $sizeDRAMTraffic\KB, $cycleDRAM, $cycleMAC, $cycleMAX, $pole";					
			#print FILEOUT "\n$index, $attribute, $numInputFeatureMapsC, $lenInputHeightH, $lenInputWidthW, $numOutputFeatureMapsK, $lenFilterHeightR, $lenFilterWidthS, $swZeroPaddingZ, $lenVerticalConvStrideH, $lenHorizontalConvStrideV, $lenHeightAfter, $lenWidthAfter,";
			
			
					
			$model[$modelIndex]{index}=$index;
			$model[$modelIndex]{attribute}=$attribute;
			$model[$modelIndex]{numInputFeatureMapsC}=$numInputFeatureMapsC;
			$model[$modelIndex]{lenInputHeightH}=$lenInputHeightH;
			$model[$modelIndex]{lenInputWidthW}=$lenInputWidthW;
			$model[$modelIndex]{numOutputFeatureMapsK}=$numOutputFeatureMapsK;
			$model[$modelIndex]{lenFilterHeightR}=$lenFilterHeightR;
			$model[$modelIndex]{lenFilterWidthS}=$lenFilterWidthS;
			$model[$modelIndex]{swZeroPaddingZ}=$swZeroPaddingZ;
			$model[$modelIndex]{lenVerticalConvStrideH}=$lenVerticalConvStrideH;
			$model[$modelIndex]{lenHorizontalConvStrideV}=$lenHorizontalConvStrideV;
			$model[$modelIndex]{lenHeightAfter}=$lenHeightAfter;
			$model[$modelIndex]{lenWidthAfter}=$lenWidthAfter;
			
			$model[$modelIndex]{Calculation}=$Calculation;
			$model[$modelIndex]{sizeInputData}=$sizeInputData;
			$model[$modelIndex]{sizeOutputData}=$sizeOutputData;
			$model[$modelIndex]{sizeWeightData}=$sizeWeightData;
			$model[$modelIndex]{sizeDRAMTraffic}=$sizeDRAMTraffic;
			$model[$modelIndex]{cycleDRAM}=$cycleDRAM;
			$model[$modelIndex]{cycleMAC}=$cycleMAC;
			$model[$modelIndex]{cycleMAX}=$cycleMAX;
			$model[$modelIndex]{pole}=$pole;
			
			$model[$modelIndex]{lenHeightAfterConvP}=$lenHeightAfterConvP;
			$model[$modelIndex]{lenWidthAfterConvQ}=$lenWidthAfterConvQ;
			
			$modelIndex++;
									
			# Assign activation(assign after output)
			# $numInputFeatureMapsC = $chOutputFeatureMaps;
			# $lenInputHeightH = $lenHeightAfter;
			# $lenInputWidthW = $lenWidthAfter;

		}
		if($flag =~ /pool/){
			
			# Parse number of nodes -> "inputs" 
			if($tmp =~ /\[(\d+), \d+, \d+\]/i){
				print "- pool node: $1\n"
			}
			if($nodeManager[$1-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$1-1]{chOutputFeatureMaps};
				$lenInputHeightH = $nodeManager[$1-1]{lenHeightAfter};
				$lenInputWidthW = $nodeManager[$1-1]{lenWidthAfter};
			}
			
			$swPoolingConv="TRUE";
			
			# Calculate activation
			$lenHeightAfter = ceil(($lenHeightAfter-$lenPoolingHeightD)/$lenVerticalPoolingStrideF)+1;
			$lenWidthAfter = ceil(($lenWidthAfter-$lenPoolingWidthE)/$lenHorizontalPoolingStrideG)+1;
			
			# Record
			$lenHeightAfterPoolingA = $lenHeightAfter;
			$lenWidthAfterPoolingB = $lenWidthAfter;
			
			# Assign output feature map to number of node(model list)			
			$nodeManager[$1]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$1]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$1]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$1]{takeBit} = 1;
			
			#print FILEOUT "$swPoolingConv, $lenPoolingHeightD, $lenPoolingWidthE, $lenVerticalPoolingStrideF, $lenHorizontalPoolingStrideG, $lenHeightAfter, $lenWidthAfter,";
			
			$modelIndex--;
			$model[$modelIndex]{swPoolingConv}=$swPoolingConv;
			$model[$modelIndex]{lenPoolingHeightD}=$lenPoolingHeightD;
			$model[$modelIndex]{lenPoolingWidthE}=$lenPoolingWidthE;
			$model[$modelIndex]{lenVerticalPoolingStrideF}=$lenVerticalPoolingStrideF;
			$model[$modelIndex]{lenHorizontalPoolingStrideG}=$lenHorizontalPoolingStrideG;
			$model[$modelIndex]{lenHeightAfter}=$lenHeightAfter;
			$model[$modelIndex]{lenWidthAfter}=$lenWidthAfter;
			
			$model[$modelIndex]{lenHeightAfterPoolingA}=$lenHeightAfterPoolingA;
			$model[$modelIndex]{lenWidthAfterPoolingB}=$lenWidthAfterPoolingB;
			
			$modelIndex++;

			# Assign activation(assign after output)
			# $numInputFeatureMapsC = $chOutputFeatureMaps;
			# $lenInputHeightH = $lenHeightAfter;
			# $lenInputWidthW = $lenWidthAfter;

		}
		if($flag =~ /relu|softmax|__mul_scalar__|LRN|batch_norm|dropout/i){
			# Parse number of nodes -> "inputs" 
			if($tmp =~ /\[(\d+), \d+, \d+\]/i){
				print "- other nodes: $1\n"
			}
			if($1 != 0 && $nodeManager[$1-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$1-1]{chOutputFeatureMaps};
				$lenHeightAfter = $nodeManager[$1-1]{lenHeightAfter};
				$lenWidthAfter = $nodeManager[$1-1]{lenWidthAfter};
			}
			# Assign output feature map to number of node(model list)			
			$nodeManager[$1]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$1]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$1]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$1]{takeBit} = 1;
		}
		if($flag =~ /transpose/i){
			# Parse number of nodes -> "inputs" 
			if($tmp =~ /\[(\d+), \d+, \d+\]/i){
				print "- flatten node: $1\n"
			}
			if($nodeManager[$1-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$1-1]{chOutputFeatureMaps};
				$lenHeightAfter = $nodeManager[$1-1]{lenHeightAfter};
				$lenWidthAfter = $nodeManager[$1-1]{lenWidthAfter};
			}
			# Assign output feature map to number of node(model list)			
			$nodeManager[$1]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$1]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$1]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$1]{takeBit} = 1;
		}
		if($flag =~ /flatten/i){
			# Parse number of nodes -> "inputs" 
			if($tmp =~ /\[(\d+), \d+, \d+\]/i){
				print "- flatten node: $1\n"
			}
			if($nodeManager[$1-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$1-1]{chOutputFeatureMaps};
				$lenInputHeightH = $nodeManager[$1-1]{lenHeightAfter};
				$lenInputWidthW = $nodeManager[$1-1]{lenWidthAfter};
			}
			# Assign output feature map to number of node(model list)			
			$nodeManager[$1]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$1]{lenHeightAfter} = $lenInputHeightH;
			$nodeManager[$1]{lenWidthAfter} = $lenInputWidthW;
			$nodeManager[$1]{takeBit} = 1;
		}
		if($flag =~ /reshape/i){
			# Parse number of nodes -> "inputs" 
			if($tmp =~ /\[(\d+), \d+, \d+\]/i){
				print "- reshape node: $1\n"
			}
			if($nodeManager[$1-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$1-1]{chOutputFeatureMaps};
				$lenHeightAfter = $nodeManager[$1-1]{lenHeightAfter};
				$lenWidthAfter = $nodeManager[$1-1]{lenWidthAfter};
			}
			# Assign output feature map to number of node(model list)			
			$nodeManager[$1]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$1]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$1]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$1]{takeBit} = 1;
		}
		if($flag =~ /broadcast_add/){
			my $match;
			# Parse number of nodes -> "inputs" 
			if(@match=($tmp =~ /\[(\d+), \d+, \d+\]/ig)){
				print "- broadcast_add node: ";
				for $i(0..$#match){
					print "$match[$i] ";
				}
				print "\n";
				
			}
			if($nodeManager[$match[0]-1]{takeBit} == 1){
				$numInputFeatureMapsC = $nodeManager[$match[0]-1]{chOutputFeatureMaps};
				$lenHeightAfter = $nodeManager[$match[0]-1]{lenHeightAfter};
				$lenWidthAfter = $nodeManager[$match[0]-1]{lenWidthAfter};
			}
			# Assign output feature map to number of node(model list)			
			$nodeManager[$match[$#match]]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$match[$#match]]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$match[$#match]]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$match[$#match]]{takeBit} = 1;
		}
		if($flag =~ /concatenate/){
			my $match;
			# Parse number of nodes -> "inputs" 
			if(@match=($tmp =~ /\[(\d+), \d+, \d+\]/ig)){
				print "- concatenate node: ";
				for $i(0..$#match){
					print "$match[$i] ";
				}
				print "\n";
				
			}
			$numInputFeatureMapsC = 0;
			for $i(0..$#match){
				print "concat node: $match[$i], $nodeManager[$match[$i]-1]{chOutputFeatureMaps}\n";
				$numInputFeatureMapsC = $numInputFeatureMapsC + $nodeManager[$match[$i]-1]{chOutputFeatureMaps};
			}
			
			$lenHeightAfter = $nodeManager[$match[0]-1]{lenHeightAfter};
			$lenWidthAfter = $nodeManager[$match[0]-1]{lenWidthAfter};

			# Assign output feature map to number of node(model list)
			$nodeManager[$match[$#match]]{chOutputFeatureMaps} = $numInputFeatureMapsC;
			$nodeManager[$match[$#match]]{lenHeightAfter} = $lenHeightAfter;
			$nodeManager[$match[$#match]]{lenWidthAfter} = $lenWidthAfter;
			$nodeManager[$match[$#match]]{takeBit} = 1;

			
		}

		$flag = "none";
		
		
   }else{
		if($flag =~ /conv|pool|dense/){
			
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
				if($tmp =~ /[\[\(](\d+)L, (\d+)L[\]\)]/i){
					$lenFilterHeightR = $1;
					$lenFilterWidthS = $2;
					print "$tmp, lenFilterHeightR = $1, lenFilterWidthS = $2\n";
				}
			}
			if($1 =~ /padding/){
				if($tmp =~ /[\[\(](\d+)L, (\d+)L[\]\)]/i){
					if($1 == 0){
						$swZeroPaddingZ = "FALSE";
					}else{
						$swZeroPaddingZ = "TRUE";
					}
					
				}
				
			}
			if($1 =~ /strides/){
				if($tmp =~ /[\[\(](\d+)L, (\d+)L[\]\)]/i){
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
				if($tmp =~ /[\[\(](\d+)L, (\d+)L[\]\)]/i){
					$lenPoolingHeightD = $1;
					$lenPoolingWidthE = $2;
					print "$tmp, lenPoolingHeightD = $1, lenPoolingWidthE = $2\n";
				}
			}
			if($1 =~ /strides/){
				if($tmp =~ /[\[\(](\d+)L, (\d+)L[\]\)]/i){
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
		# $lenFilterHeightR = $lenInputHeightH;
		# $lenFilterWidthS = $lenInputWidthW;
		$swZeroPaddingZ = "FALSE";
		$lenVerticalConvStrideH = 1;
		$lenHorizontalConvStrideV = 1;
   }
}
# Handle output
for $i (0 .. $#model){
	
	# Part of calculate by NVIDIA formula
	$model[$i]{Calculation} = $model[$i]{numInputFeatureMapsC} * $model[$i]{numOutputFeatureMapsK} * $model[$i]{lenFilterHeightR} * $model[$i]{lenFilterWidthS} * $model[$i]{lenHeightAfterConvP} * $model[$i]{lenWidthAfterConvQ};
	
	$model[$i]{sizeInputData} = ceil(ceil($model[$i]{numInputFeatureMapsC} * $model[$i]{lenVerticalConvStrideH} * $model[$i]{lenHorizontalConvStrideV} / 16.0) # 64 input channels but # is 16 in  data cube
							* 16.0 
							* ceil($model[$i]{lenInputHeightH} / $model[$i]{lenVerticalConvStrideH})
							* ceil($model[$i]{lenInputWidthW} / $model[$i]{lenHorizontalConvStrideV})
							* $byteInputData
							/ 1024.0);
	
	$model[$i]{sizeWeightData} = ceil(ceil($model[$i]{numInputFeatureMapsC} * $model[$i]{lenVerticalConvStrideH} * $model[$i]{lenHorizontalConvStrideV}) # weight is in DRAM
							* ceil($model[$i]{lenFilterHeightR} / $model[$i]{lenVerticalConvStrideH})
							* ceil($model[$i]{lenFilterWidthS} / $model[$i]{lenHorizontalConvStrideV})
							* ceil($model[$i]{numOutputFeatureMapsK})
							* $byteWeightData
							/ 1024.0);
	

	$model[$i]{cycleMAC} = ceil(ceil($model[$i]{numInputFeatureMapsC} * $model[$i]{lenVerticalConvStrideH} * $model[$i]{lenHorizontalConvStrideV} / 64.0) # 64 input channels
					* 64.0
					* $model[$i]{lenHeightAfterConvP}
					* $model[$i]{lenWidthAfterConvQ}
					* ceil($model[$i]{numOutputFeatureMapsK} / 16.0) # 16 output channels
					* 16.0
					* $model[$i]{lenFilterHeightR}
					* $model[$i]{lenFilterWidthS}
					/ $model[$i]{lenVerticalConvStrideH}
					/ $model[$i]{lenHorizontalConvStrideV}
					/ $numMultiplier
					* 16.0); # 16 cycle per MAC
	
	if($model[$i]{swPoolingConv} ne "TRUE"){
		# Mid Results of conv
		# Part of calculated by NVIDIA formula
		$model[$i]{sizeOutputData} = ceil($model[$i]{lenHeightAfterConvP}
							* $model[$i]{lenWidthAfterConvQ}
							* ceil($model[$i]{numOutputFeatureMapsK} / 16.0)
							* 16.0
							* $byteInputData
							/ 1024.0);
							
		
		$model[$i]{sizeDRAMTraffic} = $model[$i]{sizeInputData} + $model[$i]{sizeOutputData} + $model[$i]{sizeWeightData};
		$model[$i]{cycleDRAM} = $model[$i]{sizeDRAMTraffic }
						/ $bwDRAM
						* $freq;
						
		if($model[$i]{cycleDRAM} > $model[$i]{cycleMAC}){
			$model[$i]{cycleMAX} = $model[$i]{cycleDRAM};
			$model[$i]{pole} = "DRAM";
		}else{
			$model[$i]{cycleMAX} = $model[$i]{cycleMAC};
			$model[$i]{pole} = "MAC";
		}
		
		print FILEOUT "$model[$i]{index}, $model[$i]{attribute}, $model[$i]{numInputFeatureMapsC}, $model[$i]{lenInputHeightH}, $model[$i]{lenInputWidthW}, $model[$i]{numOutputFeatureMapsK}, $model[$i]{lenFilterHeightR}, $model[$i]{lenFilterWidthS}, $model[$i]{swZeroPaddingZ}, $model[$i]{lenVerticalConvStrideH}, $model[$i]{lenHorizontalConvStrideV}, $model[$i]{lenHeightAfterConvP}, $model[$i]{lenWidthAfterConvQ},,,,,,,, $model[$i]{Calculation}, $model[$i]{sizeInputData}\KB, $model[$i]{sizeOutputData}\KB, $model[$i]{sizeWeightData}\KB, $model[$i]{sizeDRAMTraffic}\KB, $model[$i]{cycleDRAM}, $model[$i]{cycleMAC}, $model[$i]{cycleMAX}, $model[$i]{pole}\n";
	}else{
		# Mid Results of conv
		# Part of calculated by NVIDIA formula
		$model[$i]{sizeOutputData} = ceil($model[$i]{lenHeightAfterPoolingA}
							* $model[$i]{lenWidthAfterPoolingB}
							* ceil($model[$i]{numOutputFeatureMapsK} / 16.0)
							* 16.0
							* $byteInputData
							/ 1024.0);
							
		
		$model[$i]{sizeDRAMTraffic} = $model[$i]{sizeInputData} + $model[$i]{sizeOutputData} + $model[$i]{sizeWeightData};
		$model[$i]{cycleDRAM} = $model[$i]{sizeDRAMTraffic }
						/ $bwDRAM
						* $freq;
						
		if($model[$i]{cycleDRAM} > $model[$i]{cycleMAC}){
			$model[$i]{cycleMAX} = $model[$i]{cycleDRAM};
			$model[$i]{pole} = "DRAM";
		}else{
			$model[$i]{cycleMAX} = $model[$i]{cycleMAC};
			$model[$i]{pole} = "MAC";
		}
	
		print FILEOUT "$model[$i]{index}, $model[$i]{attribute}, $model[$i]{numInputFeatureMapsC}, $model[$i]{lenInputHeightH}, $model[$i]{lenInputWidthW}, $model[$i]{numOutputFeatureMapsK}, $model[$i]{lenFilterHeightR}, $model[$i]{lenFilterWidthS}, $model[$i]{swZeroPaddingZ}, $model[$i]{lenVerticalConvStrideH}, $model[$i]{lenHorizontalConvStrideV}, $model[$i]{lenHeightAfterConvP}, $model[$i]{lenWidthAfterConvQ}, $model[$i]{swPoolingConv}, $model[$i]{lenPoolingHeightD}, $model[$i]{lenPoolingWidthE}, $model[$i]{lenVerticalPoolingStrideF}, $model[$i]{lenHorizontalPoolingStrideG}, $model[$i]{lenHeightAfterPoolingA}, $model[$i]{lenWidthAfterPoolingB}, $model[$i]{Calculation}, $model[$i]{sizeInputData}\KB, $model[$i]{sizeOutputData}\KB, $model[$i]{sizeWeightData}\KB, $model[$i]{sizeDRAMTraffic}\KB, $model[$i]{cycleDRAM}, $model[$i]{cycleMAC}, $model[$i]{cycleMAX}, $model[$i]{pole}\n";
	}
				
}

close(FILEIN);
close(FILEOUT); 


