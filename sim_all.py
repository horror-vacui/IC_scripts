#!/zsc/cad/util/python3/3.6.1.el6/bin/python3
# Am not aware of any other way to process a script with python3 interpreter. #!python3 does not work
# Also python3 has to be loaded manually with module load python3

import logging
from pathlib import Path
from shutil import copyfile
import subprocess
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter( logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
logger.addHandler(ch)

spe_orig 	= Path("netlist/spectre.spe")
nl_orig 	= Path("netlist/netlist")
icpro_dir	= Path(os.environ.get("ICPRO_DIR"))
results_dir = spe_orig.parent

logger.warn("example warnign")

# simulatations to run
# TODO: outsource it into a config file
l_dict = (
	{'VDD':0.9, 'VBN':3, 	'VBP':-1, 	'VDCIN':0.5, 'TEMP':60},
	{'VDD':0.9, 'VBN':2, 	'VBP':-1, 	'VDCIN':0.5, 'TEMP':60},
	{'VDD':0.9, 'VBN':0.9, 	'VBP':0, 	'VDCIN':0.5, 'TEMP':60},
	{'VDD':0.9, 'VBN':0, 	'VBP':0, 	'VDCIN':0.5, 'TEMP':60},
	{'VDD':0.8, 'VBN':3, 	'VBP':-1, 	'VDCIN':0.45, 'TEMP':60},
	{'VDD':0.8, 'VBN':2, 	'VBP':-1, 	'VDCIN':0.45, 'TEMP':60},
	{'VDD':0.8, 'VBN':0.8, 	'VBP':0, 	'VDCIN':0.45, 'TEMP':60},
	{'VDD':0.8, 'VBN':0, 	'VBP':0, 	'VDCIN':0.45, 'TEMP':60},
	{'VDD':0.5, 'VBN':3, 	'VBP':-1, 	'VDCIN':0.275, 'TEMP':60},
	{'VDD':0.5, 'VBN':2, 	'VBP':-1, 	'VDCIN':0.275, 'TEMP':60},
	{'VDD':0.5, 'VBN':0.5, 	'VBP':0, 	'VDCIN':0.275, 'TEMP':60},
	{'VDD':0.5, 'VBN':0, 	'VBP':0, 	'VDCIN':0.275, 'TEMP':60},
)

for d in l_dict:
	logger.info(f"Processing run {d}")
	p = Path(f"netlist_VDD{d['VDD']:.1f}_VBN{d['VBN']:.1f}_VBP{d['VBP']:.1f}_VIN{d['VDCIN']:.3f}_TEMP{d['TEMP']:.0f}")
	logger.info("creating the netlist directory: " + str(p))
	p.mkdir(mode=0o750, parents=True, exist_ok=True)

	logger.info("copying the required files into the netlist directories")
	spe = p / spe_orig.name
	nl  = p / nl_orig.name
	copyfile( spe_orig, spe ) 
	copyfile( nl_orig,  nl  ) 

	logger.info("substituting the run specific parameters in the spe file")
	subprocess.run(['sed','-i',
		'-e',f"s/TMP_VDD/{d['VDD']}/g",
		"-e",f"s/TMP_VBN/{d['VBN']}/g",
		"-e",f"s/TMP_VBP/{d['VBP']}/g",
		"-e",f"s/TMP_VDCIN/{d['VDCIN']}/g",
		"-e",f"s/TMP_TEMP/{d['TEMP']}/g",
		str(spe.absolute())])

	logger.info("substituting the output file paths (a paramter to the meas_freq verilogA module in the netlist)")
	res  = Path(str(p).replace("netlist", "results") + ".csv")
	sens = Path(str(res).replace("results","sensitivity"))
	logger.debug(str(res))
	logger.debug(str(sens))
    # these parameters are specific to the verilogA module I was using for the simulation.
	subprocess.run(['sed','-i',
		'-e', 's/sensitivity_file=[^ ]*/sensitivity_file="' + str(sens) + '"/',
		'-e', 's/detailed_file=[^ ]*/detailed_file="' + str(res) + '"/',
		str(nl)
	])
	logger.debug(str(nl))

	psf_dir	 = Path(str(p).replace("netlist_","psf_"))
	logger.info("Creating the PSF output directory if it does not exists already: " + str(psf_dir))
	psf_dir.mkdir(mode=0o750, parents=True, exist_ok=True)

	logger.info("Staring the simulator...")
    # subprocess.run waits for the return value of the process. For parallel simulations, use Popen.
	# subprocess.run(["spectre", "-64", '+escchars', '+log', str(psf_dir / 'spectre.out'), '-format', 'psfbin', '-raw', str(psf_dir), '++aps', str(spe)], stdout=subprocess.DEVNULL)
	subprocess.Popen(["spectre", "-64", '+escchars', '+log', str(psf_dir / 'spectre.out'), '-format', 'psfbin', '-raw', str(psf_dir), '++aps', str(spe)]) #, stdout=subprocess.DEVNULL)
