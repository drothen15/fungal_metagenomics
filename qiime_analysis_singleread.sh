#!/bin/bash

## QIIME2 PIPELINE FOR DATA Q/C AND OTU TABLE 'NOW CALLED FEATURE TABLE' GENERATION

## Before running this script run both FASTQC and BBMAP script to get trimming and other Q$

## All raw fastq files need to be in a single input directory


## Input Global Variables

## Trimming variables ## - Important!! These need to be called as arguments when executing the shell script 

echo -n 'enter trim-left: '
read trim1
echo -n 'trunc-len: '
read trun1



## Raw sequence directory
read -p  'input_dir: ' input_dirvar

## Output directory

read -p 'output_dir: ' output_dirvar



## Trained taxonomic classifier PATH ##

read -p 'taxonomic_classifier: ' taxonomic_classifiervar


## Printing input variables before executing the shell script  ##

echo
echo
echo ----------- Input Variables Set ----------
echo raw sequence input directory: $input_dirvar
echo output sequence directory: $output_dirvar
echo trim-left_f: $trim1
echo trunc-len_f: $trun1
echo taxonomic-classifier: $taxonomic_classifiervar

echo Finished. Now starting QIIME2 Pipeline

## Add Conda Path to PATH and Activate Environment ##
echo "STEP 1: Starting QIIME2 Environment from Conda"
export PATH=/programs/Anaconda2/bin:$PATH
source activate qiime2-2018.6


## Import raw sequence files into QIIME2 environment ##
echo "STEP 2: Importing sequencing files into QIIME2 environment"
qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path $input_dirvar \
  --source-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path $output_dirvar/demux-paired-end.qza



## Summary of demux ##
echo "Step 3: Summary of demux"
qiime demux summarize \
  --i-data $output_dirvar/demux-paired-end.qza \
  --o-visualization $output_dirvar/demux-paired-end.qzv



## Dada2 denoise (error correction, chimera check, trimming)
echo "Step 4: Dada2 denoise and repersentative sequence picking"
qiime dada2 denoise-single \
  --i-demultiplexed-seqs $output_dirvar/demux-paired-end.qza \
  --p-trim-left $trim1 \
  --p-trunc-len $trun1 \
  --o-table $output_dirvar/table.qza \
  --p-n-threads 40 \
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
  --i-classifier $classifier_classifiervar \
  --i-reads $output_dirvar/rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file $output_dirvar/taxonomy.qza \
  --o-visualization taxonomy.qza

## Taxonomic Barplot ##
echo "Step 8: Taxonomic Barplot Graphing"
qiime taxa barplot \
  --i-table $output_dirvar/table.qza \
  --i-taxonomy $output_dirvar/taxonomy.qza
  --o-visualization $output_dirvar taxa-bar-plot.qzv





echo Complete

