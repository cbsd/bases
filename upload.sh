#!/bin/sh
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
. ${MYDIR}/config.conf
set +e

if [ -z "${path}" ]; then
	echo "no such path: -p"
	exit 1
fi
if [ ! -r "${path}/base.txz" ]; then
	echo "no such base.txz: ${path}"
	exit 1
fi
if [ ! -r "${path}/kernel-GENERIC.txz" ]; then
	echo "no such kernel-GENERIC.txz: ${path}"
	exit 1
fi

ssh_options="-oIdentityFile=${MYDIR}/.ssh/id_ed25519 -oStrictHostKeyChecking=no -oConnectTimeout=15 -oServerAliveInterval=10 -oUserKnownHostsFile=/dev/null -oPort=${UPLOAD_SSH_PORT}"
ssh_string="ssh -q ${ssh_options} ${UPLOAD_SSH_USER}@${UPLOAD_SSH_HOST}"
scp_string="scp ${ssh_options}"

sshtest=$( timeout 30 /usr/bin/lockf -s -t0 /tmp/cbsd-upload-${ver}.lock ${ssh_string} date )
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "ssh failed"
	echo "${sshtest}"
	exit ${ret}
fi

remote_dir="${UPLOAD_SSH_ROOT}${arch}/${target_arch}/${ver}/"
sshtest=$( timeout 30 ${ssh_string} cd ${remote_dir} )
ret=$?

if [ ${ret} -ne 0 ]; then
	echo "ssh cd remote dir failed: ${remote_dir}"
	echo "${sshtest}"
	exit ${ret}
fi

${scp_string} ${path}/base.txz ${UPLOAD_SSH_USER}@${UPLOAD_SSH_HOST}:${remote_dir}/base.txz
ret=$?
if [ ${ret} -ne 0 ]; then
	echo "scp base.txz failed"
	echo "${scp_string} ${path}/base.txz ${UPLOAD_SSH_USER}@${UPLOAD_SSH_HOST}:${remote_dir}/base.txz"
	exit ${ret}
fi


${scp_string} ${path}/kernel-GENERIC.txz ${UPLOAD_SSH_USER}@${UPLOAD_SSH_HOST}:${remote_dir}/kernel.txz
ret=$?
if [ ${ret} -ne 0 ]; then
	echo "scp kernel.txz failed"
	echo "${scp_string} ${path}/kernel-GENERIC.txz ${UPLOAD_SSH_USER}@${UPLOAD_SSH_HOST}:${remote_dir}/kernel.txz"
	exit ${ret}
fi

# todo - symlink changer

# remove?
rm -rf ${destdir}
exit ${ret}
