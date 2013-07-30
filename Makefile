.PHONY: all parse clean

all: data
	@echo "Convert the xls files in data/ to .csv and run 'make parse'"

parse: data/zipcodes.csv data/niscodes.csv
	mkdir -p out
	coffee index.coffee

clean:
	rm -rf data

data:
	mkdir -p data
	wget -O data/zipcodes.xls http://www.bpost2.be/zipcodes/files/zipcodes_alpha_nl.xls
	wget -O data/niscodes.xls http://statbel.fgov.be/nl/binaries/anccom_nl%5B1%5D_tcm325-34221.xls
