#!/usr/bin/python

import os
import argparse
from rdflib import Graph

# NOTE (05/09/2025): To further generalise this script, this constant should be
# made into a argument that can be passed by the caller.
CONFIG_PATH = "/app/config/odrl-parser/"
TTL_EXT = ".ttl"
NTRIPLES_EXT = ".nt"

parser = argparse.ArgumentParser()
parser.add_argument("-r", "--replace", action="store_true")
args = parser.parse_args()

if os.path.isdir(CONFIG_PATH):
    os.chdir(CONFIG_PATH)
    for file in os.listdir():
        target = file.replace(TTL_EXT, NTRIPLES_EXT)
        if file.endswith(TTL_EXT) and (args.replace or not os.path.exists(target)):
            print(" >> Found " + file)
            graph = Graph()
            graph.parse(file, format="turtle")
            graph = graph.skolemize(basepath="http://lblod.data.gift/bnode/")
            graph.serialize(format="nt11", destination=target)
            print(" >> Wrote " + target)
else:
    print(" >> Error: path does not exist: ", CONFIG_PATH)
