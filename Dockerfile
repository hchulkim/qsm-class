FROM hchulkim/r_4.5.1:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Set quarto version
ENV QUARTO_VERSION=1.7.32

# Download and install quarto
RUN /rocker_scripts/install_quarto.sh
RUN quarto install tinytex

# Install some R packages from source to avoid error
RUN R -q -e "install.packages('stringi', type='source', repos='https://cloud.r-project.org')"
RUN R -q -e "install.packages('sf', type='source', repos='https://cloud.r-project.org')"

# Restore via lockfile first for better caching
COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided=TRUE); renv::restore(prompt=FALSE)'

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

# Run analysis
RUN make all

CMD cp -r /home/project/output/* /home/project/shared_folder/

