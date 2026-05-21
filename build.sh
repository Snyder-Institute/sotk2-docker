#!/usr/bin/env bash
#
# Build the sotk2 Docker image via buildx.
#
# Two modes:
#
#   ./build.sh local                # build native arch only, --load into local docker.
#                                   # Fast on Apple Silicon (no emulation). Tags:
#                                   #   thebiohub/sotk2:local
#                                   # Use for hands-on testing before publishing.
#
#   ./build.sh push   [version]     # build multi-arch (linux/amd64 + linux/arm64)
#                                   # and push directly to Docker Hub. Tags:
#                                   #   thebiohub/sotk2:<version>   (default 1.0.0)
#                                   #   thebiohub/sotk2:latest
#                                   # Requires docker login as a member of the
#                                   # 'thebiohub' org.
#
# Environment overrides:
#   APP_SRC=/path/to/ShinyApps-devel/sotk2   (default ~/Documents/GitHub/ShinyApps-devel/sotk2)
#   BUILDER=sotk2-multiarch                  (the buildx builder to use)
#
set -euo pipefail

MODE="${1:-}"
VERSION="${2:-1.0.0}"
IMAGE="thebiohub/sotk2"
APP_SRC="${APP_SRC:-$HOME/Documents/GitHub/ShinyApps-devel/sotk2}"
BUILDER="${BUILDER:-sotk2-multiarch}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
        sed -n '2,/^set -euo/p' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
        exit "${1:-1}"
}

if [[ "${MODE}" != "local" && "${MODE}" != "push" ]]; then
        echo "ERROR: first argument must be 'local' or 'push'" >&2
        echo >&2
        usage 1 >&2
fi

if [[ ! -d "${APP_SRC}" ]]; then
        echo "ERROR: Shiny app source not found at: ${APP_SRC}" >&2
        echo "       Set APP_SRC=/path/to/ShinyApps-devel/sotk2 and retry." >&2
        exit 1
fi

# Ensure the buildx builder exists; create on demand if not.
if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
        echo "Creating buildx builder: ${BUILDER}"
        docker buildx create --name "${BUILDER}" --driver docker-container --bootstrap
fi

case "${MODE}" in
        local)
                # Native architecture only, --load into local docker so `docker run` finds it.
                # Buildx --load only supports a single platform.
                NATIVE_ARCH="$(uname -m)"
                case "${NATIVE_ARCH}" in
                        arm64|aarch64) PLATFORM="linux/arm64" ;;
                        x86_64|amd64)  PLATFORM="linux/amd64" ;;
                        *)             echo "ERROR: unrecognized arch ${NATIVE_ARCH}" >&2; exit 1 ;;
                esac
                echo "Building ${IMAGE}:local for ${PLATFORM} (native, --load)"
                echo "  from app source : ${APP_SRC}"
                echo "  using builder   : ${BUILDER}"
                echo
                docker buildx build \
                        --builder "${BUILDER}" \
                        --platform "${PLATFORM}" \
                        -f "${SCRIPT_DIR}/Dockerfile" \
                        -t "${IMAGE}:local" \
                        --load \
                        "${APP_SRC}"
                echo
                echo "Built: ${IMAGE}:local (${PLATFORM}, in local docker)"
                echo "Test it (auto-open browser):"
                echo "  IMAGE=${IMAGE}:local ${SCRIPT_DIR}/launch.sh"
                echo "or manually:"
                echo "  docker run --rm -p 11630:11630 ${IMAGE}:local"
                echo "  open http://localhost:11630"
                ;;
        push)
                # Multi-arch, --push directly to Docker Hub.
                # Buildx multi-arch images cannot be --load'd; they must be pushed.
                echo "Building ${IMAGE}:${VERSION} multi-arch and pushing to Docker Hub"
                echo "  platforms       : linux/amd64, linux/arm64"
                echo "  from app source : ${APP_SRC}"
                echo "  using builder   : ${BUILDER}"
                echo "  tags            : ${IMAGE}:${VERSION}, ${IMAGE}:latest"
                echo
                docker buildx build \
                        --builder "${BUILDER}" \
                        --platform linux/amd64,linux/arm64 \
                        -f "${SCRIPT_DIR}/Dockerfile" \
                        -t "${IMAGE}:${VERSION}" \
                        -t "${IMAGE}:latest" \
                        --push \
                        "${APP_SRC}"
                echo
                echo "Pushed: ${IMAGE}:${VERSION} and ${IMAGE}:latest"
                echo "Verify: docker buildx imagetools inspect ${IMAGE}:${VERSION}"
                ;;
esac
