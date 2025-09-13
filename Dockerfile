FROM hchulkim/r_4.5.1:latest

# Install system deps
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ca-certificates \
    wget \
    perl \
  && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
ENV ARCH_TYPE=${TARGETARCH}

# Quarto
ENV QUARTO_VERSION=1.7.32
RUN /rocker_scripts/install_quarto.sh

# Ensure TinyTeX binaries are on PATH at build and run time
ENV PATH="/root/.TinyTeX/bin/aarch64-linux:/root/.TinyTeX/bin/x86_64-linux:${PATH}"

# --- TinyTeX install (arm64 manual, amd64 via Quarto) ---
RUN set -eux; \
  if [ "$ARCH_TYPE" = "arm64" ]; then \
    echo "(manual tinytex install for arm64)"; \
    wget -qO- "https://yihui.org/tinytex/install-unx.sh" | sh -s - --admin --no-path; \
    tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet; \
  else \
    quarto install tinytex; \
  fi

# Install some R packages from source to avoid error
RUN R -q -e "install.packages('stringi', type='source', repos='https://cloud.r-project.org')"
RUN R -q -e "install.packages('sf', type='source', repos='https://cloud.r-project.org')"

# Restore via lockfile first for better caching
COPY renv.lock renv.lock
RUN R -e 'renv::consent(provided=TRUE); renv::restore(prompt=FALSE)'

# Julia
ENV JULIA_VERSION=1.11.6
RUN /rocker_scripts/install_julia.sh
RUN julia -e "import Pkg; Pkg.add(\"DrWatson\")"
COPY Manifest.toml Project.toml .
ENV JULIA_PROJECT=/home/project
RUN julia -e "import Pkg; Pkg.activate(\".\"); Pkg.instantiate()"

# Project files
COPY . .

RUN mkdir -p shared_folder

# Build DAG
RUN make dag && mv makefile-dag.png output/

# Run analysis
RUN make all

CMD ["sh", "-c", "cp -r /home/project/output/* /home/project/shared_folder/"]
