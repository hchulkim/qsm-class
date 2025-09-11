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
papdir = output/report/
slidsdir = output/slides/
rdir = src/R/
jdir = src/julia/

## Headline build
all: $(papdir)report.pdf 

$(papdir)report.pdf: $(tabsdir)q3_linear_model.tex $(tabsdir)q4_ppml.tex $(tabsdir)q5_linear_model_solution1.tex $(tabsdir)q5_linear_model_solution2.tex $(tabsdir)q5_ppml_model_solution1.tex $(tabsdir)q5_ppml_model_solution2.tex $(figsdir)histogram_fixef.png $(tabsdir)residential_market_access.tex $(tabsdir)workplace_market_access.tex $(figsdir)residential_market_access.png $(figsdir)workplace_market_access.png $(figsdir)residential_market_access_fixed_point.png $(figsdir)workplace_market_access_fixed_point.png $(figsdir)land_rent.png  
	quarto render $(outputdir)output.qmd
	mv $(outputdir)output.pdf $(papdir)report.pdf
# all: question1_8_r question_8_10_julia

## Draw the Makefile DAG
## Requires: https://github.com/lindenb/makefile2graph
dag: makefile-dag.png
makefile-dag.png: Makefile
	make -Bnd all | make2graph | dot -Tpng -Gdpi=300 -o makefile-dag.png

# Question 1-8 R
# question1_8_r: $(tabsdir)q3_linear_model.tex $(tabsdir)q4_ppml.tex $(tabsdir)q5_linear_model_solution1.tex $(tabsdir)q5_linear_model_solution2.tex $(tabsdir)q5_ppml_model_solution1.tex $(tabsdir)q5_ppml_model_solution2.tex $(tabsdir)residential_market_access.tex $(tabsdir)workplace_market_access.tex $(figsdir)residential_market_access.png $(figsdir)workplace_market_access.png $(figsdir)histogram_fixef.png

# Question 8-10 Julia
# question_8_10_julia: $(inputdir)temp/Residence_df.csv $(inputdir)temp/Workplace_df.csv $(figsdir)residential_market_access_fixed_point.png $(figsdir)workplace_market_access_fixed_point.png

# miscellaneous
$(inputdir)temp/philly_od_tract_tract_2022.csv.gz: $(inputdir)pa_od_main_JT00_2022.csv.gz $(rdir)01_clean_raw_data.R
	Rscript $(rdir)01_clean_raw_data.R \
	 --input input.yml

$(inputdir)temp/philly_od_tract_tract_2022_with_distance.csv.gz: $(inputdir)temp/philly_od_tract_tract_2022.csv.gz $(rdir)02_calculate_distance.R
	Rscript $(rdir)02_calculate_distance.R \
	 --input input.yml

$(tabsdir)q3_linear_model.tex $(inputdir)q3_linear_model_fes.csv $(figsdir)residential_fe.png $(figsdir)workplace_fe.png &: $(inputdir)temp/philly_od_tract_tract_2022_with_distance.csv.gz $(rdir)03_est_linear_model.R
	Rscript $(rdir)03_est_linear_model.R \
	 --input input.yml

$(tabsdir)q4_ppml.tex $(inputdir)q4_ppml_fes.csv $(inputdir)temp/ek_estimate.csv $(figsdir)residential_fe_ppml.png $(figsdir)workplace_fe_ppml.png &: $(inputdir)temp/philly_od_tract_tract_2022.csv.gz $(rdir)04_est_ppml.R
	Rscript $(rdir)04_est_ppml.R \
	 --input input.yml

$(inputdir)temp/philly_od_tract_tract_2022_with_distance_ii_solution1.csv.gz $(inputdir)temp/philly_od_tract_tract_2022_with_distance_ii_solution2.csv.gz &: $(inputdir)temp/philly_od_tract_tract_2022_with_distance.csv.gz $(rdir)05_calculate_distance_ii.R
	Rscript $(rdir)05_calculate_distance_ii.R \
	 --input input.yml

$(tabsdir)q5_linear_model_solution1.tex $(inputdir)q5_linear_model_fes_solution1.csv $(tabsdir)q5_linear_model_solution2.tex $(inputdir)q5_linear_model_fes_solution2.csv $(tabsdir)q5_ppml_model_solution1.tex $(inputdir)q5_ppml_fes_solution1.csv $(tabsdir)q5_ppml_model_solution2.tex $(inputdir)q5_ppml_fes_solution2.csv &: $(inputdir)temp/philly_od_tract_tract_2022_with_distance_ii_solution1.csv.gz $(inputdir)temp/philly_od_tract_tract_2022_with_distance_ii_solution2.csv.gz $(rdir)06_linear_ppml.R
	Rscript $(rdir)06_linear_ppml.R \
	 --input input.yml

$(figsdir)histogram_fixef.png: $(inputdir)q3_linear_model_fes.csv $(inputdir)q4_ppml_fes.csv $(inputdir)temp/q5_linear_model_fes_solution2.csv $(inputdir)temp/q5_ppml_fes_solution2.csv $(rdir)06_2_histogram_fixef.R
	Rscript $(rdir)06_2_histogram_fixef.R \
	 --input input.yml

$(tabsdir)residential_market_access.tex $(tabsdir)workplace_market_access.tex $(figsdir)residential_market_access.png $(figsdir)workplace_market_access.png &: $(inputdir)temp/philly_od_tract_tract_2022.csv.gz $(inputdir)temp/ek_estimate.csv $(rdir)07_create_market_access.R
	Rscript $(rdir)07_create_market_access.R \
	 --input input.yml

$(inputdir)temp/data_julia.csv &: $(inputdir)temp/philly_od_tract_tract_2022.csv.gz $(inputdir)temp/ek_estimate.csv $(rdir)08_fixed_point_algorithm.R
	Rscript $(rdir)08_fixed_point_algorithm.R \
	 --input input.yml

$(inputdir)temp/Residence_df.csv $(inputdir)temp/Workplace_df.csv &: $(inputdir)temp/data_julia.csv $(jdir)08_2_fixed_point_algorithm.jl
	julia $(jdir)08_2_fixed_point_algorithm.jl

$(figsdir)residential_market_access_fixed_point.png $(figsdir)workplace_market_access_fixed_point.png &: $(inputdir)temp/Residence_df.csv $(inputdir)temp/Workplace_df.csv $(rdir)09_plot_fixed_point_algorithm.R
	Rscript $(rdir)09_plot_fixed_point_algorithm.R \
	 --input input.yml

$(inputdir)temp/df_brinkman_lin.csv: $(inputdir)temp/data_julia.csv $(jdir)10_brinkman_lin.jl
	julia $(jdir)10_brinkman_lin.jl

$(tabsdir)amenity.csv $(tabsdir)productivity.csv $(figsdir)land_rent.png &: $(inputdir)temp/ek_estimate.csv $(inputdir)temp/df_brinkman_lin.csv $(inputdir)temp/philly_od_tract_tract_2022.csv.gz $(rdir)10_recover_fundamentals.R
	Rscript $(rdir)10_recover_fundamentals.R \
	 --input input.yml



# reading raw data

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
	rm -f $(inputdir)temp/* $(figsdir)* $(tabsdir)* $(papdir)*

clean_raw:
	rm -f $(inputdir)*
	mkdir -p $(inputdir)temp/
	
## Helpers
.PHONY: all raw clean clean_raw
