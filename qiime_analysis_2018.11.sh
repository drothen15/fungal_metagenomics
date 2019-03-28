#!/bin/bash

## QIIME2 PIPELINE FOR DATA Q/C AND OTU TABLE 'NOW CALLED FEATURE TABLE' GENERATION

## Before running this script run both FASTQC and BBMAP script to get trimming and other Q$

## All raw fastq files need to be in a single input directory


## Input Global Variables

## Trimming variables ## - Important!! These need to be called as arguments when executing the shell script


## Exporting local variable before activation (This step was included because BioHPC changed default system locale)
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
## Setting Local Blast Datebase Variable for Brocc q2-Plugin
export BLASTDB=/workdir/fungal_metagenomics/ncbi_db_qiime/


echo -n 'enter trim-left_f: '
read trim1
echo -n 'enter trim-left_r: '
read trim2
echo -n 'enter trunc-len_f '
read trun1
echo -n 'enter trunc-len_r '
read trun2


## Raw sequence directory
read -p  'input_dir: ' input_dirvar

## Output directory

read -p 'output_dir: ' output_dirvar


## Trained taxonomic classifier PATH ##

read -p 'taxonomic-classifier: ' classifier_var

 ## Printing input variables before executing the shell script  ##

echo
echo
echo ----------- Documentation -------------
echo AUTHOR: DEREK ROTHENHEBER
echo EMAIL: derek.rothenheber@gmail.com
echo github: https://github.com/drothen15/fungal_metagenomics
echo Date Created: 9-14-18
echo Version: 2
echo
echo ----------- Input Variables Set ----------
echo raw sequence input directory: $input_dirvar
echo output sequence directory: $output_dirvar
echo taxonomic classifier: $classifier_var
echo trim-left_f: $trim1
echo trim-left_r: $trim2
echo trunc-len_f: $trun1
echo trunc-len_f: $trun2

echo Finished. Now starting QIIME2 Pipeline
sleep 5s

## Add Conda Path to PATH and Activate Environment ##
echo "STEP 1: Starting QIIME2 Environment from Conda"
export PATH=/programs/Anaconda2/bin:$PATH
source activate qiime2-2018.11


## Import raw sequence files into QIIME2 environment ##
echo "STEP 2: Importing sequencing files into QIIME2 environment"
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $input_dirvar \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path $output_dirvar/demux-paired-end.qza



## Summary of demux ##
echo "Step 3: Summary of demux"
qiime demux summarize \
  --i-data $output_dirvar/demux-paired-end.qza \
  --o-visualization $output_dirvar/demux-paired-end.qzv



## Dada2 denoise (error correction, chimera check, trimming)
echo "Step 4: Dada2 denoise and repersentative sequence picking"
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs $output_dirvar/demux-paired-end.qza \
  --p-trim-left-f $trim1 \
  --p-trim-left-r $trim2 \
  --p-trunc-len-f $trun1 \
  --p-trunc-len-r $trun2 \
  --p-n-threads 40 \
  --o-table $output_dirvar/table.qza \
  --o-representative-sequences $output_dirvar/rep-seqs.qza \
  --o-denoising-stats $output_dirvar/denoising-stats.qza



## Repersentative Sequence Picking ##
qiime feature-table tabulate-seqs \
  --i-data $output_dirvar/rep-seqs.qza \
  --o-visualization $output_dirvar/rep-seqs.qzv


## Denoising stats
echo "Step 5: Denoising stats"
qiime metadata tabulate \
  --m-input-file $output_dirvar/denoising-stats.qza \
  --o-visualization $output_dirvar/denoising-stats.qzv



## Summarize Feature Table (SV Analysis) ##
echo "Step 6: Generation of feature table (aka Species Matrix)"
qiime feature-table summarize \
  --i-table $output_dirvar/table.qza \
  --o-visualization $output_dirvar/table.qzv \
  --m-sample-metadata-file $output_dirvar/denoising-stats.qza


## Taxonomic Picking ##
echo "Step 7: Taxonomic Classification with NaiveBayes"
qiime feature-classifier classify-sklearn \
  --i-classifier $classifier_var \
  --i-reads $output_dirvar/rep-seqs.qza \
  --o-classification $output_dirvar/taxonomy.qza

qiime metadata tabulate \
  --m-input-file $output_dirvar/taxonomy.qza \
  --o-visualization $output_dirvar/taxonomy.qzv

## Taxonomic Barplot ##
echo "Step 8: Taxonomic Barplot Graphing"
qiime taxa barplot \
  --i-table $output_dirvar/table.qza \
  --i-taxonomy $output_dirvar/taxonomy.qza \
  --o-visualization $output_dirvar/taxa-bar-plot.qzv \
  --m-metadata-file $output_dirvar/denoising-stats.qza

## BROCC PLUGIN FOR BLASTn TAXONOMIC ASSIGNMENT AND BAR PLOT ##

#echo "Step 9: Assigning Taxonomy with BLASTn using Brocc Plugin"
#qiime brocc classify-brocc \
#  --i-query $output_dirvar/rep-seqs.qza \
#  --o-classification $otuput_dirvar/brocc-taxonomy.qza

#echo "Creating Visual Taxonomy File"
#qiime metadata tabulate \
#  --m-input-file $output_dirvar/brocc-taxonomy.qza \
#  --o-visualization $output_dirvar/brocc-taxonomy.qzv

#echo "Step 10: BLASTn Taxonomic Barplot Graphing"
#qiime taxa barplot \
#  --i-table $output_dirvar/table.qza \
#  --i-taxonomy $output_dirvar/brocc-taxonomy.qza \
#  --o-visualization $output_dirvar/brocc-taxa-bar-plot.qzv \
#  --m-metadata-file $output_dirvar/denoising-stats.qza


echo "COMPLETE - IF ERRORS OCCURRED THEM TROUBLESHOOT WITH LOG FILES"