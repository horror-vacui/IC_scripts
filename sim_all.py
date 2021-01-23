import logging
import subprocess
import argparse
import json
from pathlib import Path
from shutil import copyfile
from os import environ
from sys import argv

########################################################
# Initialize the logger
########################################################
logger = logging.getLogger(argv[0])
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter( logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
logger.addHandler(ch)

########################################################
# Parsing input arguments
########################################################
parser = argparse.ArgumentParser(description="Starting parallel spectre simulations")
parser.add_argument("-c", "--config", help="Filename, where the replacement patterns are stored as a JSON file. Every corner/run needs an entry. Example dictionary: [{'VDD':0.8, 'TEMP':85}, {'VDD':0.5,'TEMP':85}, {'VDD':0.8}, 'TEMP':-40},{'VDD':0.5,'TEMP':-40}].", type=Path, default=Path("./sim_config.json"), required=False)
parser.add_argument("-n", "--nice", help="nice level of the simulation process.", type=int, default=10, required=False)
parser.add_argument("-t", "--thread", help="Number of threads to use for each process.", type=int, default=4, required=False)
parser.add_argument("-d", "--dir", help="The directory where the 'netlist' and the 'spectre.spe' files are located.", type=Path, default=Path("netlist/"), required=False)
# TODO: develope an option where the number of processes is monitored. So multiple processes can run in parallel, but a new one will only start if the number of the currently running processes are below a given threshold
parser.add_argument("-s", "--serial", help="The simulations will be dispatched serially. The next simualtion will start when the previous one finishes.",  action='store_false', required=False, default=False)
parser.add_argument("--debug", help="Creates all the files and directories necessary for the simulations, but they will not be started.", action='store_true')
args = parser.parse_args()
logger.warn(args)


spe_orig 	= args.dir / "spectre.spe"
nl_orig 		= args.dir / "netlist"
icpro_dir	= Path(environ.get("ICPRO_DIR"))

########################################################
# Processing each run in the config file
########################################################
with open(args.config,'r') as f:
	l_dict = json.load(f)

for d in l_dict:
	logger.info(f"Processing run {d}")
	p = Path( "netlist_" + "_".join([f"{j}{d[j]}" for j in d.keys()]) )
	logger.debug("creating the netlist directory: " + str(p))
	p.mkdir(mode=0o750, parents=True, exist_ok=True)

	logger.info("copying the required files into the netlist directories")
	spe = p / spe_orig.name
	nl =  p / nl_orig.name
	copyfile(spe_orig, spe ) 
	copyfile(nl_orig, nl ) 
	
	# TODO: make it independent from sed, i.e. make replacement python native
	logger.info("substituting the run specific parameters in the spe file")
	l_subs = sum(  [['-e', f"s/TMP_{i}/{d[i]}/g"] for i in d.keys()],  []  )
	if args.thread <= 1:
		l_thr = [ "-e",f"s/(multithread)=[^ ]*/\1=off/"]
	else:
		l_thr = [ "-e",f"s/(nthreads)=[0-9]*/\1={args.thread}/g",
		  # "-e",f"s/(multithread)=[^ ]*/\1={'off' if args.serial else 'on'}/g",
		  "-e",f"s/(multithread)=[^ ]*/\q='on'/g"
		  	] # l_thr
	subprocess.run( ['sed','-i'] + l_subs + l_thr + [str(spe.absolute())] )

	# TODO: separate the actions for the spe and the netlist files. --> make modular and loadable at a higher level.
	# 			At the moment it is way too specific for my single test case.
	logger.info("substituting the output file paths (a paramter to the meas_freq verilogA module in the netlist)")
	res  = Path(str(p).replace("netlist", "results") + ".csv")
	sens = Path(str(res).replace("results","sensitivity"))
	logger.debug(str(res))
	logger.debug(str(sens))
	subprocess.run(['sed','-i',
		'-e', 's/sensitivity_file=[^ ]*/sensitivity_file="' + str(sens) + '"/',
		'-e', 's/detailed_file=[^ ]*/detailed_file="' + str(res) + '"/',
		str(nl)
	])
	logger.debug(str(nl))

	########################################################
	# Creating the output directories and starting the simulation
	########################################################
	psf_dir	 = Path(str(p).replace("netlist_","psf_"))
	logger.info("Creating the PSF output directory: " + str(psf_dir))
	psf_dir.mkdir(mode=0o750, parents=True, exist_ok=True)

	l_cmd = ["nice", "-%d" % args.nice, "spectre", "-64", '+escchars', '+log', str(psf_dir / 'spectre.out'), '-format', 'psfbin', '-raw', str(psf_dir), '++aps', str(spe)]
	if args.debug:
		logger.info("Run the following command to start the simulation: " + " ".join(l_cmd[2:]))
	else:
		logger.info("Staring the simulator...")
		if args.serial:
			logger.debug("Serial process. {args.serial}")
			subprocess.run(l_cmd , stdout=subprocess.DEVNULL)
		else:
			logger.debug("Parallel processes. {args.serial}")
			subprocess.Popen(l_cmd) #, stdout=subprocess.DEVNULL)
