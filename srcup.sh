#!/bin/sh
MYDIR=$( dirname `realpath $0` )

arch="noop"
target_arch="noop"

set -e
. ${MYDIR}/func.subr
set +e

cmd_string="cbsd srcup ver=${ver}"

${cmd_string}
ret=$?
exit $?
