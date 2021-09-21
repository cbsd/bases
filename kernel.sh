#!/bin/sh
MYDIR=$( dirname `realpath $0` )

set -e
. ${MYDIR}/func.subr
set +e

cmd_string=

if [ "${myarch}" != "${arch}" ]; then
	echo "not native arch"
	if [ -z "${target_arch}" ]; then
		echo "empty target_arch"
		exit 1
	fi
	cmd_string="cbsd kernel ver=${ver} arch=${arch} target_arch=${target_arch}"
else
	cmd_string="cbsd kernel ver=${ver}"
fi

${cmd_string}
ret=$?

exit $?
