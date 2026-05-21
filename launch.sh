#!/usr/bin/env bash
#
# Launch the sotk2 Shiny container and open it in the default browser.
#
# Behaviour:
#   * Runs `docker run` in the FOREGROUND so all R / shiny logs stream into
#     your terminal while you click around.
#   * A background watcher polls http://localhost:<HOST_PORT> and opens your
#     default browser as soon as shiny is ready.
#   * Ctrl-C stops the container (--rm auto-deletes it on exit).
#
# Usage:
#   ./launch.sh                       # uses latest pulled image
#   IMAGE=thebiohub/sotk2:1.1.0 ./launch.sh
#   HOST_PORT=8080 ./launch.sh        # remap container's 11630 to a different host port
#
set -euo pipefail

IMAGE="${IMAGE:-thebiohub/sotk2:latest}"
HOST_PORT="${HOST_PORT:-11630}"
CONTAINER_NAME="${CONTAINER_NAME:-sotk2}"
CONTAINER_PORT=11630
URL="http://localhost:${HOST_PORT}"

# Remove any prior container of the same name (idempotent re-launch)
if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
        echo "Removing prior container: ${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

# --- Background watcher: open browser when shiny is ready -----------------
(
        # Phase 1: wait up to 10s for the foreground `docker run` to create the container
        for _ in $(seq 1 20); do
                if docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
                        break
                fi
                sleep 0.5
        done

        # Phase 2: poll http endpoint, bail if the container disappears
        for _ in $(seq 1 60); do
                if ! docker ps --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
                        echo "[launch.sh] container ${CONTAINER_NAME} is gone, stopping watcher." >&2
                        exit 1
                fi
                if curl -sf -o /dev/null "${URL}" 2>/dev/null; then
                        echo "[launch.sh] sotk2 ready, opening ${URL}" >&2
                        case "$(uname -s)" in
                                Darwin) open "${URL}" ;;
                                Linux)  xdg-open "${URL}" >/dev/null 2>&1 || true ;;
                                *)      echo "[launch.sh] open ${URL} in your browser" >&2 ;;
                        esac
                        exit 0
                fi
                sleep 1
        done
        echo "[launch.sh] timed out waiting for ${URL}; check 'docker logs ${CONTAINER_NAME}'" >&2
) &
WATCHER_PID=$!

# Make sure the watcher dies when this script exits (Ctrl-C, normal end)
trap 'kill "${WATCHER_PID}" 2>/dev/null || true' EXIT

echo "Starting ${IMAGE}"
echo "  host port      : ${HOST_PORT}"
echo "  container port : ${CONTAINER_PORT}"
echo "  container name : ${CONTAINER_NAME}"
echo
echo "Browser will open at ${URL} once shiny is ready."
echo "Ctrl-C in this terminal stops the container."
echo "------------------------------------------------------------------"

# --- Foreground container run: logs stream here, --rm cleans up on exit ---
docker run --rm \
        -p "${HOST_PORT}:${CONTAINER_PORT}" \
        --name "${CONTAINER_NAME}" \
        "${IMAGE}"
