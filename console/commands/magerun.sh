#!/usr/bin/env bash
set -euo pipefail

DOCKERGENTO_TOOLS_DIR=tools
MAGERUN="n98-magerun2.phar"

setup_magenrun()
{
    curl -O https://files.magerun.net/n98-magerun2.phar
    # IMPORTANT:
    # Docker cp from container to host needs to be done in a not running container.
    # Otherwise the docker.hyperkit gets crazy and breaks the bind mounts
    ${COMMANDS_DIR}/stop.sh
    echo " > copying '${SERVICE_PHP}:${WORKDIR_PHP}/.' into '${HOST_DIR}'"
    CONTAINER_ID=$(${DOCKER_COMPOSE} ps -q ${SERVICE_PHP})
    docker cp ${HOST_DIR}/${MAGERUN} ${CONTAINER_ID}:${WORKDIR_PHP}/${MAGERUN}

    # Start containers again because we needed to stop them before mirroring
    ${COMMANDS_DIR}/start.sh
}

run_magerun()
{
if [ ! -f ${MAGERUN} ]; then 
	setup_magenrun
fi
${COMMANDS_DIR}/exec.sh php ${MAGERUN} "$@"
}

run_magerun "$@"