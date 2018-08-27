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
