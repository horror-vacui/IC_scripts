#!/usr/bin/python3.5
# Initial version - zti 2018-01-27

import argparse
import numpy as np
from quantiphy import Quantity 

parser = argparse.ArgumentParser(description="""Calibre LVS returns only the area and perimeter of a device in case of Property errors. Most of the devices have rectangular area. The designer needs to know the dimensions of the rectangle to fix the property error. This script will return the length of the rectangle sides. 
Note: If Calibre merged areas from multiple device geometries, then it is not a rectangle any more. If the device geometries were the same, then divide the input numbers by the number of parallel devices.""")
parser.add_argument("area", help="area of the rectangle", type=float, metavar='A')
parser.add_argument("perimeter", help="perimeter of the rectangle", type=float, metavar='P')
args = parser.parse_args()

##########################################################

A = Quantity(args.area, 'm^2')
P = Quantity(args.perimeter,'m')

a = Quantity(np.sqrt(P**2/16-A)+P/4,'m')
b = Quantity(P/2-a,'m')

print("Side 1: " + str(a)) 
print("Side 2: " + str(b))
print("\nDouble check: \nArea: " + str(Quantity(a*b,'m^2')) +"\nPerimter: " + str(Quantity(2*(a+b),'m')) )

