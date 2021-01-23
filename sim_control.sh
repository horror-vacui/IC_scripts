# I've just found it 2.5 years later. I guess it still needs some debugging
#!/bin/bash
# Batch simulations

DO_NETLISTING=1
DO_SIMULATION=1
LIB=PROS_div_zti
CELL=zz_tspc_div4
MODEL_FILE="include \"$ICPRO_DIR/resources/22FDSOI/Models/Spectre/models/design_wrapper_rf.lib.scs\" section=tt_pre"
# MODEL_FILE=include "$ICPRO_TMP/22fdx_models/design_wrapper_rf.lib.scs" section=tt_pre

# array_design=("slvt_N2nf1" "slvt" "elvt" "elvt_doublegate")
# array_mode=("sch" "ext_r" "ext_cc" "ext_rcc") # "ext_no")
array_design=("slvt")
array_mode=("sch" "ext_rcc") # "ext_no")
# array_design=("slvt")
# array_mode=("ext_rcc" "sch") # "ext_no")

################################
# function definition
################################
# $1=DESIGN, e.g. slvt_N2nf1
# $2=MODE,	e.g. ext_cc
modify_input_scs () {
	local tmp
	local f_input=input_$1_$2.scs
	cp input.scs $f_input
	if [ "$2" != "sch" -a "$2" != "ext_no" ]; then
		sed -i "/^\s*include/ s/\(section=\)tt_pre/\1tt_post/" $f_input		
#		echo "Model section changed to tt_post"
	fi 
	if [ "$2" != "sch" ]; then
		tmp_dspf="dspf_include \"$ICPRO_DIR/units/prosecco/cdslib/PROS_div_zti/tspc_div2/netlist_$1_$2/text.txt\""
		echo "$tmp_dspf" >> $f_input

	fi
	sed 	-i \
			-e "1i simulator lang=spectre" \
			-e "s/\(out_file_comment\s*=\s*\"\)[^\"]\+/\1$1_$2/"  \
			-e "s/\(detailed_file\s*=\s*\"\)[^\"]\+/\1\/home\/$(whoami)\/tspc_results\/divider_$1_$2.csv/" \
			-e "s/\(sensitivity_file\s*=\s*\"\)[^\"]\+/\1\/home\/$(whoami)\/tspc_results\/divider_sensitivity_$1_$2.csv/" \
			$f_input
#			-e "s/\(detailed_file*=\s*\"\)[^\"]\+/\1\.\/divider_$1_$1.csv/" \
#			-e "s/\(sensitivity_file*=\s*\"\)[^\"]\+/\1\.\/divider_sensitivity_$1_$1.csv/" \
}

netlist_and_run () {
	local tmp_dspf
#	local is_sch
#	echo "1st argument: $1"
#	echo "2nd argument: $2"
	if [ "$2" = "sch" -o  "$2" =  "ext_no" ]; then 
#		echo ".$2. is either sch or ext_no"
		tmp_dspf="" 
#		tmp_nl=""
	else	
		tmp_dspf="-spf=$ICPRO_DIR/units/prosecco/cdslib/PROS_div_zti/tspc_div2/netlist_$1_$2/text.txt"
#		echo "Extracted view detected: $2"
#		tmp_nl="_tt_post"
	fi
#	echo "output: ./psf_$2"
#	echo "dspf: $tmp_dspf"
	
#	cmd="spectre -64 +escchars +log ../../psf_$1_$2/spectre.out -format psfbin -raw ../../psf_$1_$2 ++aps +lqtimeout 900 -maxw 5 -maxn 5 input_$1_$2.scs $tmp_dspf" 
	cmd="spectre -64 +escchars +log ../../psf_$1_$2/spectre.out -format psfbin -raw ../../psf_$1_$2 ++aps +lqtimeout 900 -maxw 5 -maxn 5 input_$1_$2.scs" 
	echo -e "$cmd\n"
	modify_input_scs $1 $2 &&  xterm -T "sim $1_$2"  -e $cmd & # -hold
}

################################

# array_cellviews=(
# 	"config_nonrf_slvt_veriloga"
# 	"config_nonrf_slvt_ext_no_veriloga"
# 	"config_nonrf_slvt_N2nf1_veriloga"
# 	"config_nonrf_slvt_N2nf1_ext_no_veriloga"
# 	"config_nonrf_elvt_veriloga"
# 	"config_nonrf_elvt_doublegate_veriloga"
# 	"config_nonrf_elvt_ext_no_veriloga"
# 	"config_nonrf_elvt_doublegate_ext_no_veriloga"
# )
# 
# if [ "$DO_NETLISTING" -ne "0" ]; then
# 	for i_config in ${array_cellviews[@]}; do
# 		netlist -l $LIB -c $CELL -v ${i_config}
# 	done;
# fi

# array_design=("slvt_N2nf1" "slvt" "elvt" "elvt_doublegate")
# array_mode=("sch" "ext_r" "ext_cc" "ext_rcc")
# for i_design in ${array_design[@]}; do
# 	echo $i
# 	for i_mode in ${array_mode[@]}; do
# 		if [ $j == "sch" ] 
# 			then tmp=""
# 			else tmp=$j
# 		fi	
# 		echo "tmp: $tmp"
# 		echo "design: $i"
# 		echo "mode: $j"
# 		echo "config_nonrf_${i_design}_${tmp}_veriloga"
# 		echo "-------------"
# 	done
# done

# ISSUE: how to catch if there is an error in netlisting?
#					 -e "/^global/a\ninclude \"$ICPRO_DIR/resources/22FDSOI/Models/Spectre/models/design_wrapper_rf.lib.scs\" section=tt_pre\n\n" \
for i_design in ${array_design[@]}; do
	array_dir=("config_nonrf_${i_design}_veriloga" "config_nonrf_${i_design}_ext_no_veriloga")
	if [[ "$DO_NETLISTING" -ne 0 ]]; then 
		for view in ${array_dir[@]}; do
			xterm -T "Netlisting: $view" -e netlist -l $LIB -c $CELL -v $view 
			pwd_tmp=$(pwd)
			echo "Netlist post-prcessing in /home/$(whoami)/simulation/$LIB/$CELL/spectre/$view/netlist"
			cd "/home/$(whoami)/simulation/$LIB/$CELL/spectre/$view/netlist"
			sed -i -e '/^modelParameter/i\\ninclude "..\/..\/analysis.dat"\n' \
					 -e "/^global/a${MODEL_FILE}" \
					 -e "0,/^parameters/{s/^parameters.*$/include \"..\/..\/parameters.dat\"/}" \
					 -e 's/^saveOptions.*$/\ninclude "..\/..\/save_opt.dat"\n/' \
					 -e '/^\w\+ info .*$/d' \
			input.scs
#			sed '/^\s*include / s/\(section\s*=\s*\)tt_pre/\1tt_post/' input.scs > input_tt_post.scs
			cd $pwd_tmp
		done
	fi # netlisting

	if [[ "$DO_SIMULATION" -ne 0 ]]; then 
		# running sch, ext_r, ext_rcc, ext_cc sims
		for i_mode in ${array_mode[@]}; do
			pwd_tmp=$(pwd)
			cd "/home/$(whoami)/simulation/$LIB/$CELL/spectre/config_nonrf_${i_design}_veriloga/netlist"
			echo "Simulating ${i_design}_${i_mode}"
#			echo "Changing Dir into: /home/$(whoami)/simulation/$LIB/$CELL/spectre/config_nonrf_${i_design}_veriloga/netlist"
			#xterm -hold -T "sim: ${i_design}_${i_mode}" -e "netlist_and_run ${i_design} ${i_mode}" &
			netlist_and_run ${i_design} ${i_mode} &
			cd $pwd_tmp
		done
		# running ext_no sim
		pwd_tmp=$(pwd)
#		echo "Changing Dir into: /home/$(whoami)/simulation/$LIB/$CELL/spectre/config_nonrf_${i_design}_ext_no_veriloga/netlist"
		cd "/home/$(whoami)/simulation/$LIB/$CELL/spectre/config_nonrf_${i_design}_ext_no_veriloga/netlist"
		# xterm -hold -T "sim: ${i_design}_ext_no" -e "netlist_and_run ${i_design} ext_no" -hold &
		netlist_and_run ${i_design} ext_no &
		cd $pwd_tmp

	fi # simulation

done

