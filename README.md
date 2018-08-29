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

1. Add QIIME2 to $PATH and activate QIIME Environment
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


