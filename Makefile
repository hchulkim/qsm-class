################################
# Makefile for analysis report
#
# Maintainer: HK
################################

## Directory vars (usually only these need changing)
inputdir = input/
outputdir = output/
figsdir = output/figures/
tabsdir = output/tables/
papdir = output/paper/
slidsdir = output/slides/

## Headline build
all: 

## Draw the Makefile DAG
## Requires: https://github.com/lindenb/makefile2graph
dag: makefile-dag.png
makefile-dag.png: Makefile
	make -Bnd all | make2graph | dot -Tpng -Gdpi=300 -o makefile-dag.png

raw: 


clean:
	rm -f $(inputdir)* $(figsdir)* $(tabsdir)* $(papdir)* $(slidsdir)*
	
## Helpers
.PHONY: all clean raw
