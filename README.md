# Clinical Fungal Metagenomics for Vet Molecular Diagnostics
This is a collection of shell and python scripts used for fungal metagenomics using various regions of 28S rRNA
and the more common ITS region. Note -  This pipeline is optmized to work in Cornell's HPC environment, but can
easily be used on other platforms.

This analysis pipeline utilizes the following:
1. QIIME2 installed via conda environment
2. Python 3.6.5 & Python 2.7
3. Pycogent python package
4. FastQC (0.11.5) and BBMap (37.50) programs

# Read quality and other QC metrics (FastQC and BBMap)
1. Add QC programs to $PATH

```bash
export PATH=/programs/FastQC-0.11.5:$PATH
export PATH=/programs/bbmap-37.50:$PATH
```
2. Concatenate all forwards and reverse reads
"Within directory containing all raw fastq.qz files" 
```bash
gunzip *R1* | gunzip *R2* | cat *R1* > cat-r1-fastq | cat *R2* cat-r2-fastq
```
3. Run FastQC on concatenated foward (R1) and reverse (R2) Reads
```bash
mkdir fastqc-output
fastqc cat-r1-fastq -o fastqc-output/ -t 40 --nogroup
```
 "note: -t = number of threads and --nogroup = show statstics for each base position (i.e. don't group by 10bps)
    
4. Transfer html file to desktop and view in web-browser
 I like using MobaXterm for a windows shh client because scp is much easier/faster, for mac users do the following in a local terminal
```bash
scp username@servername.edu:/absolute/path/to/file path/on/local/machine/
```
 
5. Grab read length distribution using awk or BBMap shell script

awk
```bash
awk 'NR%4 == 2 {lengths[length($0)]++ ; counter++} END {for (l in lengths) {print l, lengths[l]}; print "total reads: " counter}' cat-r1.fastq > readlength-r1.txt

awk 'NR%4 == 2 {lengths[length($0)]++ ; counter++} END {for (l in lengths) {print l, lengths[l]}; print "total reads: " counter}' cat-r2.fastq > readlength-r2.txt
```
or BBMap Shell
```bash
readlength.sh in=cat-r1-fastq out=histogram-r1.txt | readlength.sh in=cat-r2-fastq out=histogram-r2.txt
``` 

# Train NaiveBayes (sklearn) Classifier in QIIME2 Environment
 This procedure is for constructing novel classifiers - this example uses the latest SILVA database and creates classifiers on different domains of the 28S LSU rRNA

1. Add Anaconda2 to to $PATH and activate QIIME2 Environment
```bash
export PATH=/programs/Anaconda2/bin:$PATH
source activate qiime2-2018.6 
```

2. Download lastest SILVA Database Containing 28S rRNA and Taxonomy File

 There are two choices, either the comprehensive or reference. The comprehensive is much larger with quality checked rRNA sequences over 300bp,
 the reference containes rRNA sequneces of high quality at least 1900bp long.  

Comprehensive database
```bash
wget http://ftp.arb-silva.de/release_132/Exports/SILVA_132_LSUParc_tax_silva.fasta.gz  
wget http://ftp.arb-silva.de/release_132/Exports/taxonomy/taxmap_embl_lsu_parc_132.txt.gz
```

Reference database
```bash
wget http://ftp.arb-silva.de/release_132/Exports/SILVA_132_LSURef_tax_silva.fasta.gz
wget http://ftp.arb-silva.de/release_132/Exports/taxonomy/taxmap_embl_lsu_parc_132.txt.gz
```


3. Reformat FASTA file and Taxonomy Database so that they meet the QIIME environment requirements 
 i.e. Make sure U is converted to T, eliminate non-ASCII characters, asterisks "*" removed, and taxonomy file contains full-length taxonomic assignments even if it doesn't exist (i.e. <k_fungi;sk_Dikaraya;p_Basidiomycota;c_____;o_____;f_____;g_____;s_____>)

These following python scripts are from either [@walterst](https://gist.github.com/walterst) or [@mikerobeson](https://github.com/mikerobeson/Misc_Code/tree/master/SILVA_to_RDP) with minor modifications/adjustments

export python 2 path Pycogent was written in python 2.7
```bash
export PYTHONPATH=/programs/cogent/lib64/python2.7/site-packages/
```

run <prep_silva_data.py>
```bash
gunzip SILVA_132_LSUParc_tax_silva.fasta.gz

./prep_silva_data.py <SILVA_132_LSUParc_tax_silva.fasta.gz> <taxonomy.outfile.txt> <sequence.outfile.fasta>
```

remove non-ASCII characters
```bash
./parse_nonstandard_chars.py <taxonomy.outfile.txt> > <parsed.taxonomy.file.txt>
```

Make taxonomy file compatiable for classifier in QIIME2
```bash
./prep_silva_taxonomy_file.py <parsed.taxonomy.file.txt> <taxonomy.rdp.outfile.txt>
```

Cluster SILVA FASTA file at 99% using QIIME1 pick.otus.py
 I have qiime1 installed in a seperate conda environment, see http://qiime.org/install/install.html for help
```bash
source deactivate qiime2-2018.6

source active qiime1

pick_otus.py -i <sequence.outfile.fasta> -s 0.99 --threads 40 -o <99-clustered-sequence.outfile>
```

Now pick a repersentative set of sequences from the OTU file clustered at 99%
```bash
pick_rep_set.py -i <99-clustered-sequence.outfile.txt> -f <sequence.outfile.fasta> -o <rep-set-seqs-99clustered.fasta>
```
note : -i requires the OTU mapping file from pick_otus.py -f is the formated FASTA file containing all sequences (pre-clustering)

Now the headers in the rep-set-seqs-99clustered.fasta file need to be fixed, the OTU identifier needs to be removed along with the white space.
Run fix_fasta_labels.py
```bash
./fix_fasta_labels.py <rep-set-seqs-99clustered.fasta> <fixed-rep-set-seqs-99clustered.fasta>
```

Import taxonomy file and final 99% clustered fasta file into QIIME2 environment

```bash
source deactivate qiime1
source activate qiime2-2018.11

qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path fixed-rep-set-seqs-99clustered.fasta \
  --output-path fixed-rep-set-seqs-99clustered.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --source-format HeaderlessTSVTaxonomyFormat \
  --input-path taxonomy.rdp.outfile.txt \
  --output-path ref-taxonomy.qza
```

Extract reference reads using specific primers.
 These primers are used to extract the 28S D1 region of the LSU rRNA, from [Tedersoo et al.](https://mycokeys.pensoft.net/article/4852/)

```bash
qiime feature-classifier extract-reads \
  --i-sequences fixed-rep-set-seqs-99clustered.fasta \
  --p-f-primer ACSCGCTGAACTTAAGC \
  --p-r-primer TTCCCTTTYARCAATTTCAC \
  --o-reads 28SD1-ref-seqs.qza
```

Train the classifier from the extracted reads

```bash
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads 28SD1-ref-seqs.qza \
  --i-reference-taxonomy ref-taxonomy.qza \
  --o-classifier 28sd1-99-classifier.qza
```

Alternatively the 28S classifier can be trained on the entire gene (This seems to work better when benchmarked against ITS classification)
```bash
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads 28SD1-ref-seqs.qza \
  --i-reference-taxonomy ref-taxonomy.qza \
  --o-classifier 28s-99-classifier.qza
```


# Taxonomic Classification of Samples
The script automates the workflow in QIIME2 from QC to taxonomic assignment

Outputs include:

rep-seqs.qzv
table.qzv
taxonomy.qzv
barplot.qzv

Paired-end data is run through this shell
```bash
qiime_analysis_2018.11.sh
```

Single-end data is run through this shell
```bash
qiime_analysis_singleread_2018.11.sh
```

Paired-end script will prompt for the following input variables
** INPUT DIRECTORY CAN ONLY HAVE GZIP FASTQ FILES ** 
```bash
1. trim-left_f: int
2. trim-left_r: int
3. trunc-len_f: int
4. trunc-len_r: int
5. input_dir:   $PATH
6. output_dir:  $PATH
7. taxonomic_classifier: $PATH
```


# Alternative Taxonomic Classification with BLASTn Using Brocc q2-Plugin

By default the qiime_analysis_2018.11.sh & qiime_analysis_singleread.sh use trained taxonomic classifiers for the ITS and 28S genes.
Both classifiers use the SILVA databases of curated sequences, which can tend to result in a fair amount of the sample only be assigned to higher levels of taxonomy.

Assigning taxonomy with the NCBI database open up much more (less curated) data to be used for taxonomic assignment, and can give a little more information on samples that couldn't being resolved well with a trained classifer.

  
-The following plugin q2-brocc built by [@kylebittinger](https://github.com/kylebittinger/q2-brocc) works in the QIIME2 environment and has already been installed on Cornell's BioHPC


1. After running the analysis script the qiime environment will need to be re-activated, visit Cornell's BioHPC website to view the latest activation instructions.

2. Export your the path to the NCBI database as a locale variable
```bash
export BLASTDB=/path/to/NCBI_db/
```
- NOTE: If you're having trouble with setting up a NCBI database visit [@kylebittinger](https://github.com/kylebittinger/q2-brocc) for more detailed instructions


2. Post QIIME2 activation move to the directory with the (.qza) and (.qzv) data files and run the following commands.

```bash
#Assigning Taxonomy with BLASTn using Brocc Plugin
qiime brocc classify-brocc \
  --i-query $output_dirvar/rep-seqs.qza \
  --o-classification $otuput_dirvar/brocc-taxonomy.qza

#Creating Visual Taxonomy File
qiime metadata tabulate \
  --m-input-file brocc-taxonomy.qza \
  --o-visualization brocc-taxonomy.qzv

#BLASTn Taxonomic Barplot Graphing"
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy brocc-taxonomy.qza \
  --o-visualization brocc-taxa-bar-plot.qzv \
  --m-metadata-file denoising-stats.qza
 ```
