#!/bin/sh
# ./loop.sh -a amd64 -t amd64 -v 14.0
# ./loop.sh -a arm64 -t aarch64 -v 14.0
# ./loop.sh -a riscv -t riscv64 -v 14.0
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
. ${MYDIR}/config.conf
set +e

jobname_conf="jobs-bases-${arch}-${target_arch}-${ver}.conf"

fetch -o /tmp/loop.$$ ${SCHEDULER_URL}/${jobname_conf}
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "error: fetch -o /tmp/loop.$$ ${SCHEDULER_URL}/${jobname_conf}"
	exit ${ret}
fi

build_per_week=

. /tmp/loop.$$

rm -f /tmp/loop.$$

if [ -n "${build_per_week}" ]; then
	echo "no build_per_week params in ${SCHEDULER_URL}/${jobname_conf}"
	exit ${ret}
fi

echo "build_per_week settings: ${build_per_week}"

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
echo "${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch} > ${log}"
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

echo "${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir}"
${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir}
if [ ${ret} -ne 0 ]; then
	echo "error: ${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir}"
fi

exit ${ret}
