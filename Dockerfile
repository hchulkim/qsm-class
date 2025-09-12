FROM hchulkim/r_4.5.1:latest

# Install dependencies
# Base packages
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    wget \
    librsvg2-bin \
    perl \
    texlive-fonts-extra \
  && rm -rf /var/lib/apt/lists/*

# Access the build arch provided by Docker (e.g., amd64, arm64)
ARG TARGETARCH
# Persist it for later layers
ENV ARCH_TYPE=${TARGETARCH}

# Set quarto version
ENV QUARTO_VERSION=1.7.32

# Download and install quarto
RUN /rocker_scripts/install_quarto.sh

# Install tinytex (manual script on arm64; Quarto helper on amd64)
RUN set -eux; \
  if [ "$ARCH_TYPE" = "arm64" ]; then \
    echo "(manual tinytex install for arm64)"; \
	wget -qO- "https://yihui.org/tinytex/install-unx.sh" | sh -s - --admin --no-path; \
  else \
    quarto install tinytex; \
  fi

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

