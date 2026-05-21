# sotk2 Docker image

Docker packaging for the [sotk2](https://github.com/Snyder-Institute/sotk2) Shiny app. The image bundles the demo data so a single `docker run` is sufficient to explore the package end to end without local R setup.

Image registry: <https://hub.docker.com/r/thebiohub/sotk2> <br />
App source: <https://github.com/Snyder-Institute/sotk2-shiny>

## Quick start

The one-command path uses the bundled launcher, which starts the container, waits for the app to be ready, and opens it in your default browser:

```bash
docker pull thebiohub/sotk2:1.1.0
curl -O https://raw.githubusercontent.com/Snyder-Institute/sotk2-docker/main/launch.sh
chmod +x launch.sh
./launch.sh
```

Stop with `docker stop sotk2`.

If you'd rather invoke `docker` directly:

```bash
docker pull thebiohub/sotk2:1.1.0
docker run --rm -p 11630:11630 thebiohub/sotk2:1.1.0
open http://localhost:11630
```

The container serves on port `11630` internally; map it to whatever host port you like (the example uses `11630:11630`).

## Run modes — FULL vs LITE

The image starts in **FULL mode** by default — every Tutorial input is live (correlation method, datasets, threshold, community detection algorithm, rewiring weights), and sotk2 recomputes on demand. This is the recommended experience for users running the image locally.

To switch to **LITE mode** — a browse-only experience served against the precomputed analysis, with recompute controls hidden — override at run time:

```bash
docker run --rm -p 11630:11630 -e SOTK2_MODE=lite thebiohub/sotk2:1.1.0
```

LITE mode is intended for public-facing or low-resource deployments where recompute is not desirable.

## What's inside

- R 4.5 (base: [`rocker/r-ver:4.5`](https://hub.docker.com/r/rocker/r-ver), multi-arch)
- `sotk2` v1.0.0 (pinned to commit `1cf8155`)
- The standard CRAN dependencies of `sotk2`, plus `shiny`, `commonmark`, `BiocManager`, `Biobase` (Bioconductor — needed by NMF)
- The sotk2 Shiny app from [`Snyder-Institute/sotk2-shiny`](https://github.com/Snyder-Institute/sotk2-shiny) including the bundled demo data (GLASS, IVYGAP, HEILAND cNMF outputs, GLASS annotations, and the precomputed `soObj.RDS`)

Each architecture is ~860 MB; the multi-arch manifest (linux/amd64 + linux/arm64) means Docker auto-selects the right binary on Intel/AMD Linux, Apple Silicon, and AWS Graviton hosts. The first pull takes a few minutes; subsequent pulls reuse cached layers.

## Tags

| Tag | Points at |
|---|---|
| `1.0.0` | sotk2 R package commit `1cf8155`; ShinyApps-devel app source; no SOTK2_MODE |
| `1.1.0` | sotk2 R package commit `1cf8155`; sotk2-shiny app source; FULL default, LITE via env override |
| `latest` | Whatever the newest released tag is at any moment |

Pin to a specific version in production (`thebiohub/sotk2:1.1.0`), not `latest`.

## Building locally

```bash
# 1. Populate the demo data in sotk2-shiny (one-time, ~5 min):
cd ~/Documents/GitHub/sotk2-shiny
Rscript scripts/setup_data.R

# 2. Build the image:
cd ~/Documents/GitHub/sotk2-docker
./build.sh local         # native arch, --load into local docker (fast)
./build.sh push 1.1.0    # multi-arch (amd64 + arm64), push to Docker Hub
```

The `build.sh` wrapper assumes the Shiny app source lives at `~/Documents/GitHub/sotk2-shiny`. Override with `APP_SRC=/your/path ./build.sh local`.

Multi-arch builds use `docker buildx` with the `sotk2-multiarch` builder. On Apple Silicon, the arm64 layer builds natively while amd64 uses Rosetta (slower, but runs natively on x86 hosts after push).

## License

[MIT](LICENSE). The bundled R packages and data each carry their own licenses; see the [sotk2 package documentation](https://Snyder-Institute.github.io/sotk2/) for details.
