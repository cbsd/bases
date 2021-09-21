#!/bin/sh
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
set +e

tempdir=$( mktemp -d )
cmd_string=

if [ "${myarch}" != "${arch}" ]; then
	echo "not native arch"
	if [ -z "${target_arch}" ]; then
		echo "empty target_arch"
		exit 1
	fi
	cmd_string="cbsd mkdistribution ver=${ver} arch=${arch} target_arch=${target_arch} destdir=${tempdir}"
else
	cmd_string="cbsd mkdistribution ver=${ver} destdir=${tempdir}"
fi

logfile=$( mktemp )
trap "/bin/rm -f ${logfile}" HUP INT ABRT BUS TERM EXIT

${cmd_string} > ${logfile} 2>&1
ret=$?

if [ ${ret} -eq 0 ]; then
	echo ${tempdir}
else
	cat ${logfile}
fi

exit ${ret}
