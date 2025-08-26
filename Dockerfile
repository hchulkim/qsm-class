FROM hchulkim/r_4.5.1:master-e8ada17073138a2f323b2a7e80f0c51eac1f438e

# Restore via lockfile first for better caching
COPY renv.lock renv.lock
RUN R -e "renv::consent(provided=TRUE); renv::restore(prompt=FALSE)"

# Install Julia 1.11.6
ENV JULIA_VERSION=11.11.6
RUN /rocker_scripts/install_julia.sh

# Install Julia packages and manage dependencies
COPY Manifest.toml Project.toml .
ENV JULIA_PROJECT=/home/project
RUN julia -e "import Pkg; Pkg.activate(\".\"); Pkg.instantiate()"

# Then copy the rest
COPY . .

# make output and shared folder
RUN mkdir -p output/tables output/figures output/paper shared_folder

# Build DAG
RUN make dag

# Put DAG into output
RUN mv makefile-dag.png output/makefile-dag.png

CMD mv /home/project/output/* /home/project/shared_folder/

