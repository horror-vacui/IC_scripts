# This script generates the corners for a multi-directory PSS  simulation

import json
from numpy import arange

l_vdd = [0.5, 0.8, 0.9]
l_vdd = [0.8, 0.9]
# l_vdd = [0.9]
#l_temp = arange(-40,125,10)
#l_temp = [40]
l_d = []
for v in [0.8]:
	for i in arange(0.25,0.701,0.05):
		for t in arange(-40,125,10):
			l_dict = [{'VBN':0, 'VBP':0}, {'VBN':v, 'VBP':0}, {'VBN':2, 'VBP':-1}, {'VBN':3, 'VBP':-1}]
			for d in l_dict:
		 		d.update({'VDCIN':round(i*v/0.025)*0.025, 'VDD':float(v), 'TEMP':float(t)}) 
			# print(l_dict)
			l_d.append(l_dict)

# flatten l_d
l_out = [i for s in l_d for i in s]
json.dump(obj=l_out, fp=open("sim_config_etspc_gen.json","w"), sort_keys=True, indent=1)
