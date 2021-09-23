#!/bin/sh
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
. ${MYDIR}/config.conf
set +e

tempdir=$( mktemp -d )
cmd_string=

jobname_file="mkdistribution-${arch}-${target_arch}-${ver}"
log_file="${LOG_DIR}/${jobname_file}-${log_date}.log"

if [ "${myarch}" != "${arch}" ]; then
	echo "not native arch: ${myarch}/${arch}" >> ${log_file} 2>&1
	if [ -z "${target_arch}" ]; then
		echo "empty target_arch" >> ${log_file} 2>&1
		exit 1
	fi
	cmd_string="cbsd mkdistribution ver=${ver} arch=${arch} target_arch=${target_arch} destdir=${tempdir}"
else
	cmd_string="cbsd mkdistribution ver=${ver} destdir=${tempdir}"
fi

${cmd_string} > ${log_file} 2>&1
ret=$?

if [ ${ret} -eq 0 ]; then
	echo ${tempdir}
else
	cat ${log_file}
fi

exit ${ret}
