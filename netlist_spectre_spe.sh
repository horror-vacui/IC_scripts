#!/bin/bash
# testing extension of the netlist script
# run after netlisting from the netlist directory
# 2018-04-03: now the spectre.spe file also requires a simulator lang=spectre statement...

# Before every change, diff writes the location of the changes. In our case there will be twoinfo lines. The sanity check is that there should not be any ">" in the file

SPE_FILE="spectre.spe"

# need to add that line to the beginning of the file, otherwise spectre assumes that this is a pspice file....
if [ -f netlist ]; then
	echo -n  "Checking whether the first line of the netlist includes the spectre lang statement: "
	#if [ ! $(sed -n "1p" netlist | grep "simulator lang=spectre") ]; then
	if [[ ! $(sed -n "1p" netlist) = *"spectre"* ]]; then
		echo '[-]'
		echo 'Adding "simulator lang=spectre statement to netlist"'
		sed -i "1i simulator lang=spectre" netlist
	else echo "[+]"
	fi
fi

# If the spe exists it will not overwrite it.
if [ -f $SPE_FILE ]; then
	echo "spectre.spe already exists. Will not be recreated."
	exit 98
fi

# I want to source the netlist. I do not want it in the main file.
diff -a --suppress-common-lines input.scs netlist > $SPE_FILE

# Check that no lines start with ">"; Exit if that's the case
if [ $( grep -q "^>" $SPE_FILE)]
then
	echo "netlist has more than input.scs. Something is strange here...."
	exit 99
fi

# delete first line
# add include
#remove the "<" signs from the lines
sed -i -e "1d" -e "s/^[^<>].*/include \"netlist\"\n\n\n/" -e "s/^< //" $SPE_FILE
# list paramters in new lines:
sed -i '/^parameters /	s/\s\+/\t\\ \n\t/g' $SPE_FILE
echo "spectre.spe file was created."
