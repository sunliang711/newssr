#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import logging
import json
import sys

LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
DATE_FORMAT = "%Y/%m/%d %H:%M:%S %p"
#logging.basicConfig(level=logging.DEBUG, format=LOG_FORMAT, datefmt=DATE_FORMAT)
#logging.basicConfig(filename='my.log', level=logging.DEBUG, format=LOG_FORMAT, datefmt=DATE_FORMAT)

def main():
    if len(sys.argv) == 1:
        print("missing congfile file")
        sys.exit(1)
    with open(sys.argv[1]) as f:
        data = f.read()
    o = json.loads(data)
    with open(sys.argv[1]+'.ports','w') as out:
        try:
            for port in o['port_password']:
                out.write(port+"\n")
        except KeyError as e:
            print('Error: No key ' + str(e))
if __name__ == '__main__':
    main()
