#!/bin/sh
MYDIR=$( dirname `realpath $0` )

arch="noop"
target_arch="noop"

set -e
. ${MYDIR}/func.subr
. ${MYDIR}/config.conf
set +e

[ ! -d ${LOG_DIR} ] && mkdir -p ${LOG_DIR}

cmd_string="cbsd srcup ver=${ver}"

jobname_file="srcup-${arch}-${target_arch}-${ver}"
log_file="${LOG_DIR}/${jobname_file}-${log_date}.log"

${cmd_string} >> ${log_file} 2>&1
ret=$?
exit ${ret}

