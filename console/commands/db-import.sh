#!/usr/bin/env bash
set -euo pipefail

usage()
{
    printf "${YELLOW}Usage:${COLOR_RESET}\n"
    echo "  db-import <import file>"
    echo ""
    echo "Example:"
    printf "  ${GREEN}dockergento db-import db.sql${COLOR_RESET}\n"
}

if [ "$#" == 0 ] || [ "$1" == "--help" ]; then
    usage
    exit 0
fi

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

gunzip -c $1 | ${DOCKER_COMPOSE_EXEC} -T ${SERVICE_DB} /usr/bin/mysql -u magento -pmagento magento