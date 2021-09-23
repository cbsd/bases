#!/bin/sh
# ./loop.sh -a amd64 -t amd64 -v 14.0
# ./loop.sh -a arm64 -t aarch64 -v 14.0
# ./loop.sh -a riscv -t riscv64 -v 14.0
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
. ${MYDIR}/config.conf
set +e

loop() {
	jobname_conf="${jobname_file}.conf"
	jobname_result="/var/db/${jobname_file}.result"

#	todo: get global.conf first
#	then overwrite per-job

#	fetch -o /tmp/loop.$$ ${SCHEDULER_URL}/${jobname_conf}
#	ret=$?

#	if [ ${ret} -ne 0 ]; then
#		echo "error: fetch -o /tmp/loop.$$ ${SCHEDULER_URL}/${jobname_conf}"
#		exit ${ret}
#	fi

#	build_per_week=
	last_success_build_time=
	last_success_build_duration=0

#	. /tmp/loop.$$

#	echo "conf file:"
#	cat /tmp/loop.$$

#	rm -f /tmp/loop.$$

#	if [ -z "${build_per_week}" ]; then
#		echo "no build_per_week params in ${SCHEDULER_URL}/${jobname_conf}"
#		exit ${ret}
#	fi

	if [ -r ${jobname_result} ]; then
		echo "read last result: ${jobname_result}" >> ${log_file} 2>&1
		. ${jobname_result}
	else
		touch ${jobname_result}
	fi
#	echo "build_per_week settings: ${build_per_week}"

	st_time=$( /bin/date +%s )

	if [ -n "${last_success_build_time}" -a "${last_success_build_duration}" != "0" ]; then
		# 1 week = 604800 seconds
		build_time_week="604800"
		build_deadline_time=$(( st_time - build_time_week ))
		if [ ${last_success_build_time} -gt ${build_deadline_time} ]; then
			echo "last_success_build_time still in deadline range: ${last_success_build_time} > ${build_deadline_time}" >> ${log_file}
			exit 0
		else
			echo "deadline, time to build: ${last_success_build_time} < ${build_deadline_time}" >> ${log_file}
		fi
	else
		echo "no last_success_build_time, time to build" >> ${log_file}
	fi

	${MYDIR}/base.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date}
	ret=$?

	if [ ${ret} -ne 0 ]; then
		echo "error: ${MYDIR}/base.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date}" >> ${log_file}
		exit ${ret}
	fi

	${MYDIR}/kernel.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date}
	ret=$?

	if [ ${ret} -ne 0 ]; then
		echo "error: ${MYDIR}/kernel.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date}" >> ${log_file}
		exit ${ret}
	fi

	log=$( mktemp )
	trap "rm -f ${log}" HUP INT ABRT BUS TERM EXIT
	echo "${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date} > ${log}" >> ${log_file}
	${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date} > ${log} 2>&1
	ret=$?

	if [ ${ret} -ne 0 ]; then
		echo "error: ${MYDIR}/mkdistribution.sh -v ${ver} -a ${arch} -t ${target_arch} -d ${log_date}" >> ${log_file}
		cat ${log}
		rm -f ${log}
	fi

	dist_dir=$( grep . ${log} )
	rm -f ${log}
	trap "" HUP INT ABRT BUS TERM EXIT

	echo "${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir} -d ${log_date}" >> ${log_file}
	${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir} -d ${log_date}
	ret=$?
	if [ ${ret} -ne 0 ]; then
		echo "error: ${MYDIR}/upload.sh -v ${ver} -a ${arch} -t ${target_arch} -p ${dist_dir} -d ${log_date}" >> ${log_file}
		exit ${ret}
	fi

	end_time=$( /bin/date +%s )
	diff_time=$(( end_time - st_time ))

	sysrc -qf ${jobname_result} last_success_build_time="${end_time}"
	sysrc -qf ${jobname_result} last_success_build_duration="${diff_time}"
	echo "loop done in ${diff_time}" >> ${log_file}
	exit 0
}

jobname_file="loop-${arch}-${target_arch}-${ver}"
log_file="${LOG_DIR}/${jobname_file}-${log_date}.log"

if [ -n "${lock}" ]; then
	loop
	exit 0
else
	# recursive execite via lockf wrapper
	[ ! -d "${LOG_DIR}" ] && mkdir -p ${LOG_DIR}
	log_date=$( date "+%Y-%m-%d-%H-%M-%S" )
	log_file="${LOG_DIR}/${jobname_file}-${log_date}.log"
	echo "get lock: ${GIANT_LOCK_FILE}" >> ${log_file}
	lockf -s -t10 ${GIANT_LOCK_FILE} ${MYDIR}/loop.sh -z lock -a ${arch} -t ${target_arch} -v ${ver} -d ${log_date}
fi

exit 0
