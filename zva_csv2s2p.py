#!/usr/bin/python3
import skrf as rf
import pandas as pd
import re, argparse

parser = argparse.ArgumentParser(description="converting R&S ZVA's trace csv data into touchstone format")
parser.add_argument('fn_in', metavar='f_in', type=str, help='input csv file')
parser.add_argument('fn_out', metavar='f_out', type=str, help='input csv file')
args = parser.parse_args()

df = pd.read_csv(args.fn_in, header=2, comment="!", sep="\t")
my_header = "# Hz S DB R 50"

for idx, col in enumerate(df.columns):
    print("%d : %s" % (idx, col))

for i in range(len(df.columns)):
    if ":" in df.columns[i]:
        split = df.columns[i].split(':')
        if split[0] == 'db': # DB
            col_name = 'dB' + split[1].split('_')[1]  # db:Trc._Sxy
            df[col_name] = df.iloc[:,i]
        if split[0] == 'ang': # phase
            col_name = 'Ph' + split[1].split('_')[1]  # db:Trc._Sxy
            df[col_name] = df.iloc[:,i]
    if "freq" in df.columns[i]:
        col_name = "freq"
        df[col_name] = df.iloc[:,i]

f_out = open(args.fn_out,'w')
f_out.write("!converted from ZVA's csv trace format\n")

f_out.write('!freq\tdBS11\tPhS11\tdB21\tPh21\tdB12\tPhS12\tdBS22\tPh22\n')
f_out.write(my_header + "\n")

for idx,row in df.iterrows():
    f_out.write("\t".join(["%f" %i for i in [row['freq'],row['dBS11'],row['PhS11'],row['dBS21'],row['PhS21'],row['dBS12'],row['PhS12'],row['dBS22'],row['PhS22']]]) + "\n")

f_out.close()

