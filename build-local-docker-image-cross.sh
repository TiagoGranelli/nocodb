#!/bin/bash
# Build a local Docker image for a specified platform.
#
# Usage:
#   ./build-local-docker-image-cross.sh                        # builds for linux/amd64
#   ./build-local-docker-image-cross.sh linux/arm64            # builds for linux/arm64
#   ./build-local-docker-image-cross.sh linux/arm/v7           # builds for linux/arm/v7
#
# Supported platforms: linux/amd64, linux/arm64, linux/arm/v7

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
LOG_FILE="${SCRIPT_DIR}/build-local-docker-image-cross.log"
PLATFORM="${1:-linux/amd64}"
IMAGE_TAG="nocodb-local"
CONTAINER_NAME="nocodb-local"

echo "==> Target platform: ${PLATFORM}" | tee "${LOG_FILE}"

echo "==> Stopping and removing existing container/image" | tee -a "${LOG_FILE}"
docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rmi "${IMAGE_TAG}" >/dev/null 2>&1 || true

echo "==> Installing dependencies" | tee -a "${LOG_FILE}"
cd "${SCRIPT_DIR}"
pnpm bootstrap 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"

echo "==> Building nc-gui" | tee -a "${LOG_FILE}"
export NODE_OPTIONS="--max_old_space_size=16384"
cd "${SCRIPT_DIR}/packages/nc-gui"
pnpm run generate 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"

echo "==> Copying nc-gui artifacts" | tee -a "${LOG_FILE}"
rsync -rvzh --delete ./dist/ "${SCRIPT_DIR}/packages/nocodb/docker/nc-gui/" 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"

echo "==> Building nocodb backend" | tee -a "${LOG_FILE}"
cd "${SCRIPT_DIR}/packages/nocodb"
pnpm run docker:build 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"

echo "==> Setting up Docker buildx" | tee -a "${LOG_FILE}"
if ! docker buildx inspect nocodb-cross-builder >/dev/null 2>&1; then
    docker buildx create --name nocodb-cross-builder --use 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"
else
    docker buildx use nocodb-cross-builder 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"
fi

echo "==> Building Docker image for ${PLATFORM}" | tee -a "${LOG_FILE}"
docker buildx build \
    --platform "${PLATFORM}" \
    -f Dockerfile.local \
    -t "${IMAGE_TAG}" \
    --load \
    . 1>>"${LOG_FILE}" 2>>"${LOG_FILE}"

echo "" | tee -a "${LOG_FILE}"
echo "Docker image \"${IMAGE_TAG}\" built successfully for ${PLATFORM}." | tee -a "${LOG_FILE}"
echo "Run it with:" | tee -a "${LOG_FILE}"
echo "  docker run -d -p 3333:8080 --name ${CONTAINER_NAME} ${IMAGE_TAG}" | tee -a "${LOG_FILE}"
