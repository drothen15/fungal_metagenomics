#!/usr/bin/env python

"""Usage
python fix_fasta_labels.py X Y
where X is the input fasta file, Y is the output fasta file
The second string following a split on white space will be written
as the label in the output fasta, this is intended to make a label in a 
fasta file generated from QIIME's pick_rep_set.py match the original 
sequence ID rather than the OTU ID.""" 

from sys import argv

from cogent.parse.fasta import MinimalFastaParser

input_fasta = open(argv[1], "U")
output_fasta = open(argv[2], "w")

for label,seq in MinimalFastaParser(input_fasta):
    curr_label = " ".join(label.split(" ")[1:])
    output_fasta.write(">%s\n%s\n" % (curr_label, seq))
