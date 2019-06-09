#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#for python2 use print function
from __future__ import print_function
import logging
import sys
import hashlib

LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
DATE_FORMAT = "%Y/%m/%d %H:%M:%S %p"
#logging.basicConfig(level=logging.DEBUG, format=LOG_FORMAT, datefmt=DATE_FORMAT)
#logging.basicConfig(filename='my.log', level=logging.DEBUG, format=LOG_FORMAT, datefmt=DATE_FORMAT)

def readchunks(filename):
    with open(filename,'rb') as fh:
        chunk = fh.read(8096)
        while chunk:
            yield chunk
            chunk = fh.read(8096)

def md5hex(filename):
    v = sys.version_info
    m = hashlib.md5()
    for chunk in readchunks(filename):
        # if v.major == 3:
            # chunk = chunk.encode()
        m.update(chunk)
    return m.hexdigest()

def usage():
    """Usage: md5.py <input file>"""
    pass

def main():
    if len(sys.argv) < 2:
        print(usage.__doc__)
        return 1
    print(md5hex(sys.argv[1]),end='')

if __name__ == '__main__':
    main()


