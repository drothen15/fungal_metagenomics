#!/usr/bin/env python

from sys import argv
# Usage: python parse_to_7_taxa_levels.py X Y
# where X is the input taxonomy mapping file, Y is the output taxonomy mapping file
# Purpose is to parse output of Mike Robeson's script to force taxa into
# 7 levels.

taxa_mapping = open(argv[1], "U")
parsed_taxa = open(argv[2], "w")

for line in taxa_mapping:
    curr_line = line.strip()
    curr_id = curr_line.split()[0]
    taxa = ' '.join(curr_line.split()[1:]).split(';')
    
    last_taxa = taxa[-1]
    taxa_depth = len(taxa)
    for curr_taxa in taxa:
        if len(curr_taxa) in [5, 6]:
            last_taxa = curr_taxa
            taxa_depth = taxa.index(curr_taxa)
            break

    # If depth is 7 slice off first 7 levels
    if taxa_depth == 7:
        final_taxa = ";".join(taxa[0:7])
    # If less than 7, pad out empty levels with 'unclassified'
    elif taxa_depth < 7:    
        last_named_level = taxa[taxa_depth - 1].split('__')[1]
        for n in range(taxa_depth, 7):
            taxa[n] = taxa[n] + last_named_level
        final_taxa = ";".join(taxa[0:7])
    # If more than 7 levels, get the first 4 levels, plus last 3 named levels
    elif taxa_depth > 7:
        final_taxa = ";".join(taxa[0:4] + taxa[taxa_depth-3:taxa_depth])

    parsed_taxa.write("%s\t%s\n" % (curr_id, final_taxa))
