#!/usr/bin/env python


import argparse

parser = argparse.ArgumentParser(description='Creates every single signal of a given signal bus with a given length.', epilog="For a 12 bit adc<11:0>, the signal; bus name is adc and it's length is 12")
parser.add_argument('sig', action='store', metavar='signal', help="signal bus name.")
parser.add_argument('sig_width', action='store', type=int, help="signal bus width.")
parser.add_argument('-l', action='store_true', default=False, required=False, help="Uses '_' between the signal basename and the bit number. If it is not set '<' and '>' wil be used. For example: if -l is set then 'vectorize abc 3' will generate the following output: abc_2 abc_1 abc_0")

# args = parser.parse_args('adc 12 '.split())
args = parser.parse_args()

while args.sig_width > 0:
	if args.l:
		print args.sig + "_" + str(args.sig_width),
	else:
		print args.sig + "<" + str(args.sig_width) + ">",
	args.sig_width = args.sig_width -1


