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

 
