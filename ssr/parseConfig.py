#!/usr/bin/env python

import argparse
import json

def main():
    parser = argparse.ArgumentParser(description="parse config.json file")

    parser.add_argument("config",help="specify config file")
    parser.add_argument("key",help="specify key in config file")

    arg = parser.parse_args()

    with open(arg.config) as f:
        data = f.read()
    js = json.loads(data)

    try:
        print(js[arg.key])
    except KeyError:
        pass

if __name__ == "__main__":
    main()
