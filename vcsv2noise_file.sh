#!/bin/bash
# Convert a vcsv file into a text file which can be loaded into a vdc/idc source
# The noise performance of the biasing circuitry can be simulated and exported into a vcsv file. This way the biasing circuitry can be replaced with an ideal source in the simulation, resulting in simulation time reduction.
# Zoltan Tibenszky 2020-03-06

f_vcsv="$1"
f_out="${f_vcsv%.*}.txt"

if [ -z "$f_vcsv" ]
then
	echo "Usage: $(basename $0) <vcsv_file>"
else	
	echo Processing "$f_vcsv"
	sed '1,6d' $f_vcsv > $f_out
	sed -i 's/,/ /g' $f_out
fi
