################################################################################
# create_d64.py - Python program to create D64 file and add PRG files to it
#

from d64 import DiskImage
from os import path
from pathlib import Path

base_path = path.dirname(path.abspath(__file__))
base_path = path.join(base_path, "..")
d64_file_path = path.join(base_path,"d64","Amok.d64")

#PRG files to include
prg_list = ["AMOK 8K.PRG","AMOK.PRG"]

#DEL files to include, these are used to add text labels in the D64 file
del_list = ["----------------","FOR EXPANDED 8K+"," OR UNEXPANDED  ","VIC (SAME GAME) ","................"]

disk_label = b"AMOK"
disk_id = b"00"
if not path.exists(d64_file_path):
    DiskImage.create("d64", Path(d64_file_path), disk_label, disk_id)

d64_image = DiskImage(d64_file_path, mode='w')
with d64_image as image:
    for prg_name in prg_list:
        prg_on_d64_image = image.path(prg_name.replace(".PRG","").encode()).open(mode="w", ftype="prg")
        with open(path.join(base_path,"prg",prg_name), "rb") as file:
            prg_on_d64_image.write(file.read())
        prg_on_d64_image.close

    for del_name in del_list:
        del_on_d64_image = image.path(del_name.encode()).open(mode="w", ftype="del")
        del_on_d64_image.close

    image.close
