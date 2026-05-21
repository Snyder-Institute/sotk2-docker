# sotk2 Docker image

Docker packaging for the [sotk2](https://github.com/Snyder-Institute/sotk2) Shiny app. The image bundles the demo data so a single `docker run` is sufficient to explore the package end to end without local R setup.

Image registry: <https://hub.docker.com/r/thebiohub/sotk2>

## Quick start

The one-command path uses the bundled launcher, which starts the container, waits for the app to be ready, and opens it in your default browser:

```bash
docker pull thebiohub/sotk2:1.0.0
curl -O https://raw.githubusercontent.com/Snyder-Institute/sotk2-docker/main/launch.sh
chmod +x launch.sh
./launch.sh
```

Stop with `docker stop sotk2`.

If you'd rather invoke `docker` directly:

```bash
docker pull thebiohub/sotk2:1.0.0
docker run --rm -p 11630:11630 thebiohub/sotk2:1.0.0
open http://localhost:11630
```

The container serves on port `11630` internally; map it to whatever host port you like (the example uses `11630:11630`).

## What's inside

- R 4.5 on Ubuntu (base: `rocker/shiny:4.5`)
- `sotk2` v1.0.0 (pinned to commit `1cf8155`)
- The standard CRAN dependencies of `sotk2`
- The sotk2 Shiny app from [`ShinyApps-devel/sotk2`](https://github.com/Snyder-Institute) including the bundled demo data (~236 MB of `.RDS` files: GLASS, IVYGAP, HEILAND cNMF outputs, GLASS annotations and expression matrix, and the precomputed `soObj`)

The final image is ~2–3 GB. The first pull takes a few minutes; subsequent pulls reuse cached layers.

## Tags

| Tag | Points at |
|---|---|
| `1.0.0` | sotk2 R package commit `1cf8155` (release of 2026-05-20) |
| `latest` | Whatever the newest released tag is at any moment |

Pin to a specific version in production (`thebiohub/sotk2:1.0.0`), not `latest`.

## Building locally

```bash
git clone https://github.com/Snyder-Institute/sotk2-docker.git
cd sotk2-docker
./build.sh              # builds 1.0.0 and latest
```

The `build.sh` wrapper assumes the Shiny app source lives at `~/Documents/GitHub/ShinyApps-devel/sotk2`. Override with `APP_SRC=/your/path ./build.sh`.

The image targets `linux/amd64` regardless of host architecture (`--platform linux/amd64`); on Apple Silicon the container runs under QEMU emulation, which is fine for local testing but slower than a native Linux host.

## License

[MIT](LICENSE). The bundled R packages and data each carry their own licenses; see the [sotk2 package documentation](https://Snyder-Institute.github.io/sotk2/) for details.
