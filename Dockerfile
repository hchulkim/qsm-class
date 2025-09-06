FROM hchulkim/r_4.5.1:master-e8ada17073138a2f323b2a7e80f0c51eac1f438e

# Avoid binaries during restore, then preinstall stringi with bundled ICU
ENV RENV_CONFIG_INSTALL_TRY_BINARIES=false
RUN R -e 'install.packages("stringi", type="source", configure.vars="ICU_BUNDLE=1")'

# Restore via lockfile first for better caching
COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided=TRUE); renv::restore(prompt=FALSE, rebuild=c("sf"))'

# Install Julia 1.11.6
ENV JULIA_VERSION=1.11.6
RUN /rocker_scripts/install_julia.sh
RUN julia -e "import Pkg; Pkg.add(\"DrWatson\")"

# Install Julia packages and manage dependencies
COPY Manifest.toml Project.toml .
ENV JULIA_PROJECT=/home/project
RUN julia -e "import Pkg; Pkg.activate(\".\"); Pkg.instantiate()"

# Then copy the rest
COPY . .

# make shared folder
RUN mkdir shared_folder

# Build DAG
RUN make dag

# Put DAG into output
RUN mv makefile-dag.png output/

CMD mv /home/project/output/* /home/project/shared_folder/

