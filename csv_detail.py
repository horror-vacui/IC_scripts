import logging, argparse, csv, re
import pandas as pd
from os import listdir
from numpy import log10

parser = argparse.ArgumentParser(description="Returns data about the two-column CSV files in the current directory: X@Ymin, Ymin, Xmin, Xmax")
re_op = re.compile("sensitivity_VDD(?P<vdd>[^_]+)_VBN(?P<vbn>[^_]+)_VBP(?P<vbp>[^_]+)_VDCIN(?P<vin>[^_]+)_TEMP(?P<temp>[^\.]+).csv")

l_tmp = []
# l_tmp_header = ['file', 'X@Ymin', 'Ymin', 'Ymin_dBm', 'Xmin', 'Xmax']
l_tmp_header = ['vdd','vbn','vbp','vin','temp', 'X@Ymin', 'Ymin', 'Ymin_dBm', 'Xmin', 'Xmax']
# go over all csv files
for f in listdir():
	m = re_op.match(f)
	if m:
#		print(f"match! {f}")
		print(m.group())
		dfi = pd.read_csv(f, names=('x','y'), dtype=float, skiprows=1)
		# check if it has two columns
		if len(dfi.columns) == 2:
			xmin, ymin = dfi.min(axis=0)
			xmax, ymax = dfi.max(axis=0)
			# there might be multiple consecutive frequency points with minimum Y value
			x_at_ymin = dfi[dfi.y == ymin].x.mean()
			# l_tmp.append( [f, x_at_ymin, ymin, 10*log10(ymin**2/100)+30, xmin, xmax] )
			l_op = [float(i) for i in [m.group('vdd'), m.group('vbn'), m.group('vbp'), m.group('vin'), m.group('temp')] ]
			print(l_op)

			l_tmp.append( l_op + [ x_at_ymin, ymin, 10*log10(ymin**2/100)+30, xmin, xmax] )

df = pd.DataFrame(l_tmp, columns=l_tmp_header).sort_values(['vdd','vbn','vbp','vin','temp'])
pd.options.display.max_colwidth = 60
print(df)
