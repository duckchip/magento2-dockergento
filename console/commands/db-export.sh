#!/usr/bin/env bash
set -euo pipefail

usage()
{
    printf "${YELLOW}Usage:${COLOR_RESET}\n"
    echo "  db-import <import file>"
    echo ""
    echo "Example:"
    printf "  ${GREEN}dockergento db-export db.sql${COLOR_RESET}\n"
}

sync_all_from_container_to_host()
{
    # IMPORTANT:
    # Docker cp from container to host needs to be done in a not running container.
    # Otherwise the docker.hyperkit gets crazy and breaks the bind mounts
    ${COMMANDS_DIR}/stop.sh

    printf "${GREEN}Copying db dumps from container to host${COLOR_RESET}\n"
    rm -rf ${HOST_DIR}/${MAGENTO_DIR}/${DB_DUMP_DIR}/*

    echo " > copying '${SERVICE_PHP}:${WORKDIR_PHP}/${DB_DUMP_DIR}' into '${HOST_DIR}/${DB_DUMP_DIR}/${DB_NAME}.sql.gz'"
    CONTAINER_ID=$(${DOCKER_COMPOSE} ps -q ${SERVICE_PHP})
    docker cp ${CONTAINER_ID}:${WORKDIR_PHP}/${DB_DUMP_DIR}/${DB_NAME}.sql.gz ${HOST_DIR}/${DB_DUMP_DIR}/${DB_NAME}.sql.gz

    # Start containers again because we needed to stop them before mirroring
    ${COMMANDS_DIR}/start.sh
}


: ${EXEC_OPTIONS:=""}

if [ ${TTY_DISABLE} == true ]; then
    EXEC_OPTIONS="${EXEC_OPTIONS} -T"
fi

DOCKER_COMPOSE_EXEC="${DOCKER_COMPOSE} exec"
if [ "${EXEC_OPTIONS}" != "" ]; then
    DOCKER_COMPOSE_EXEC="${DOCKER_COMPOSE_EXEC} ${EXEC_OPTIONS}"
fi
if [[ "${MACHINE}" == "windows" && ${TTY_DISABLE} == false ]]; then
    USE_WINPTY=$(command -v winpty && test -t 1 && echo true || echo false)
    if [[ ${USE_WINPTY} == true ]]; then
        DOCKER_COMPOSE_EXEC="winpty ${DOCKER_COMPOSE_EXEC}"
    fi
fi

if [ ! -d ${DB_DUMP_DIR} ]; then 
	mkdir ${DB_DUMP_DIR}
fi


DB_NAME=`date +%Y-%m-%d-%T`

${COMMANDS_DIR}/exec.sh mkdir ${DB_DUMP_DIR} || true
${COMMANDS_DIR}/magerun.sh db:dump --quiet --no-interaction --add-routines --strip="@stripped pulsestorm_commercebug_log" --compression gzip ${DB_DUMP_DIR}/${DB_NAME}
sync_all_from_container_to_host