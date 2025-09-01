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

raw: $(inputdir)pa_od_main_JT05_2020.csv.gz $(inputdir)pa_od_main_JT05_2021.csv.gz $(inputdir)pa_od_main_JT05_2022.csv.gz

$(inputdir)pa_od_main_JT05_2020.csv.gz $(inputdir)pa_od_main_JT05_2021.csv.gz $(inputdir)pa_od_main_JT05_2022.csv.gz &:
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/od/pa_od_main_JT00_2020.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/od/pa_od_main_JT00_2021.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/od/pa_od_main_JT00_2022.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/rac/pa_rac_SA01_JT00_2020.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/rac/pa_rac_SA01_JT00_2021.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/rac/pa_rac_SA01_JT00_2022.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/wac/pa_wac_SI03_JT00_2020.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/wac/pa_wac_SI03_JT00_2021.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/wac/pa_wac_SI03_JT00_2022.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/wac/pa_wac_SA01_JT00_2020.csv.gz"
	wget -nc -P $(inputdir) "https://lehd.ces.census.gov/data/lodes/LODES8/pa/pa_xwalk.csv.gz"


clean:
	rm -f $(inputdir)* $(figsdir)* $(tabsdir)* $(papdir)* $(slidsdir)*
	
## Helpers
.PHONY: all clean raw
