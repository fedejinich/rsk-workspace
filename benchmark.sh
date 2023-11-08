#!/bin/bash

rm -f *.png &&\
rm -f *.csv &&\
npx hardhat run scripts/fhBallotScript.js --network regtest &&\
python3 charts.py
