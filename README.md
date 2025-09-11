# qsm-class
This is a repo for my coding assignment for REAL 9440

## IMPORTANT

This replication package runs all the analyses necessary to create a report `output/paper/report.pdf` in which I report and discuss the results of Tasks 3-10.

## 0. Computational requirements

We strongly suggest following the requirements to install and set up the environment to run the analysis.

### Memory, storage and hardware Requirements

The code was last run on a **Intel-based laptop with Linux Ubuntu 22.04 LTS (or 24.04) with 1TB of total storage and 64GB of RAM (Main)** and **Apple Sillicon M2 Max MacbookPro with Asahi Linux with 1TB of total storage and 96GB of RAM**. Information on number of CPUs and cores is posted below: 

- CPU(s):                                22 
- Thread(s) per core:                   2
- Core(s) per socket:                   16
- Socket(s):                            1 

### OS-Specific Considerations

- Linux (Ubuntu, Fedora (asahi linux), etc) is highly recommended; MacOS is supported (However, you might need to be careful if you use Apple Sillicon since it is based on ARM architecture).
- Windows is not officially supported. Users may encounter issues running the result. However, you will probably be able to run the results by manually running the source codes. You will probably have issues with using `Docker` and build automation tool `GNU Make`.

### Bash (terminal)

Portions of the code use bash scripting, which may require Linux or Unix-like terminal.

### System Dependencies (only for Linux)

Some R packages used here could require external system libraries. On Linux, these must be installed manually. To identify required system packages:

```r
remotes::system_requirements(os = 'ubuntu', os_release = '16.04',
                             path = 'renv/library/R-3.4/x86_64-pc-linux-gnu/sf/')
```

This issue is mostly solved if you use the `Dockerfile` provided in the replication package.

## 1. Software requirements

For full reproducibility, this workflow requires:
- [Bash](https://www.gnu.org/software/bash/) [Free]
- [Docker CLI](https://www.docker.com) [Free]
- [R](https://www.r-project.org/) [Free]
- [Julia](https://julialang.org/) [Free]

For now, it is only adapted for Linux or OSX (Apple) environments.

#### Dependency management

It is important to set up dependency management for the programming languages we use for replication and reproducibility. Here are lists of management program that I use:

- `R`: I use `renv` package.
- `Julia`: I just use `Pkg`.

## 2. Folders

##### `src`

- This folder contains all the code that builds data and performs analyses.
- All intermediary data results should be redirected into `input/temp`.
- All output tables and figures used for creating the report were redirected into `output/tables` and `output/figures` respectively.
  
##### `input`

- A folder that contains all the input data.
- Has a subfolder `temp`, which contains intermediary data.
  
##### `output`

- A folder that contains all the outputs.
- Has subfolders that contain figures and tables.

## 3. Data

For this assignment, I use **LEHD LODES** commuting flow data. To be specific, I use `origin-destination` flow data of Philadelphia County for the year 2022 (Version 8). The data is in census block-block level. I also use Geography crosswalk data provided by **LODES**. You can check the source link I use to download the raw data from `Makefile` in the replication package.

## 4. Instructions to Replicators

This section gives instructions to run the replication package. There are two options:

### Use `Docker` (highly recommended)

1. Use terminal to navigate to the root project directory containing the `Dockerfile` file.
2. Type `sudo docker build -t qsm .` in the terminal. This will start the docker build process.

> **IMPORTANT**: Depending on your computer, there can be some issues in the buildup stage. Skip this if you do not have any issue running the above command.
> - If the above command fails to fetch the necessary package to install from the network, try this command instead: `sudo docker build --network=host -t qsm .`
> - If your computer architecture is in **ARM** (which is the case for Apple Silicon), docker build might fail. In this case, try this: `sudo docker build --platform=linux/amd64 -t qsm .`
> - If docker build still fails, resort to option 2.

3. Create a folder in your local machine to retrieve the results. e.g. `/home/username/Documents/output`
4. Type `sudo docker run --rm -v /home/username/Documents/result:/home/project/shared_folder:rw qsm`
5. The results will be stored inside your `output` local folder.

### Manually setup necessary project environment and run `GNU Make`

If you don't want to use `Docker`, you can also manually setup necessary project environment and use `GNU Make` to run the whole analysis.

#### Setup necessary project environment

1. Open `R` console from the top-level project directory.
2. Use `renv::restore()` to install the packages in project library.
3. Open `julia` REPL.
4. Use `Pkg` in `julia` to instantiate the project environment.

The entire pipeline now can be executed using the **`Makefile`** master script:

```bash
make
```

> 🛠 **Important:** The `Makefile` must be placed in the top-level project directory — parallel to the `src/` and `input/` folders — for the paths to resolve properly.

On Windows, users may need to install [GNU Make](https://www.gnu.org/software/make/) manually. macOS and Linux users typically have it pre-installed.

If preferred, users can run the `R` and `julia` scripts manually. Each script is prefixed with a number that indicates its order of execution. 




