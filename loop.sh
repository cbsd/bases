#!/bin/sh
# ./loop.sh -a amd64 -t amd64 -v 14.0
# ./loop.sh -a arm64 -t aarch64 -v 14.0
# ./loop.sh -a riscv -t riscv64 -v 14.0
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
set +e

${MYDIR}/base.sh -v ${ver} -a ${arch} -t ${target_arch}
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "error: ${MYDIR}/base.sh -v ${ver} -a ${arch} -t ${target_arch}"
	exit ${ret}
fi

${MYDIR}/kernel.sh -v ${ver} -a ${arch} -t ${target_arch}
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "error: ${MYDIR}/kernel.sh -v ${ver} -a ${arch} -t ${target_arch}"
	exit ${ret}
fi

log=$( mktemp )
trap "rm -f ${log}" HUP INT ABRT BUS TERM EXIT
${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch} > ${log} 2>&1
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "error: ${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch}"
	cat ${log}
	rm -f ${log}
fi

dist_dir=$( grep . ${log} )
rm -f ${log}
trap "" HUP INT ABRT BUS TERM EXIT

${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir}
if [ ${ret} -ne 0 ]; then
	echo "error: ${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir}"
fi

exit ${ret}
