#!/bin/bash

pip install --no-cache-dir --disable-pip-version-check --root-user-action=ignore -r requirements.txt

python generate_datadump_and_dcat.py "$@"
