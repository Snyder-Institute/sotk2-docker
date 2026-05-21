# syntax=docker/dockerfile:1.7
#
# sotk2 Shiny app - public Docker image
#
# Build is driven by ./build.sh which targets buildx. Two modes:
#   ./build.sh local            # native arch only, --load into local docker
#   ./build.sh push 1.0.0       # multi-arch (linux/amd64 + linux/arm64), --push
#
# Run:
#   docker run --rm -p 3838:3838 thebiohub/sotk2:1.0.0
#   open http://localhost:3838
#

FROM rocker/r-ver:4.5

# --- System libraries required by the R package stack (NMF, igraph, ggplot2, etc.)
#     rocker/r-ver is the multi-arch base (linux/amd64 + linux/arm64). rocker/shiny
#     would have pre-installed Shiny Server but is amd64-only, and we bypass
#     Shiny Server anyway by invoking shiny::runApp directly in CMD.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libxml2-dev libcurl4-openssl-dev libssl-dev \
        libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev \
        libpng-dev libtiff5-dev libjpeg-dev \
        libgit2-dev libglpk-dev libgsl-dev libxt-dev \
        pandoc \
    && rm -rf /var/lib/apt/lists/*

# --- CRAN dependencies (shiny is installed from CRAN since rocker/r-ver doesn't bundle it)
RUN install2.r --error --skipinstalled \
        remotes shiny markdown commonmark BiocManager

# --- Bioconductor dependency of NMF (Biobase is not on CRAN)
RUN R -e "BiocManager::install('Biobase', update = FALSE, ask = FALSE); \
        stopifnot('Biobase' %in% installed.packages()[,1])"

# --- sotk2 v1.0.0 (pinned to release commit; switch to a git tag once upstream tags it)
RUN R -e "options(Ncpus = parallel::detectCores()); \
        remotes::install_github('Snyder-Institute/sotk2', \
                ref     = '1cf8155', \
                upgrade = 'never'); \
        stopifnot('sotk2' %in% installed.packages()[,1])"

# --- App bundle
# Build context is the Shiny app dir (~/Documents/GitHub/ShinyApps-devel/sotk2).
# Bundle layout inside the image:
#   /srv/shiny-server/sotk2/{app.R, Rsource/, data/, www/, *.md, *.html}
COPY . /srv/shiny-server/sotk2/

EXPOSE 11630

# Run sotk2 directly (one R process per container; no shiny-server daemon).
CMD ["R", "--quiet", "--no-save", "-e", \
        "shiny::runApp('/srv/shiny-server/sotk2', host='0.0.0.0', port=11630)"]
