#!/bin/sh
pgm="${0##*/}"          # Program basename
progdir="${0%/*}"       # Program directory

REPO_DIR="${1}"
# /usr/obj/usr/jails/src/src_13.2/src/repo/FreeBSD:13:amd64/13.2"
pkg_num=0

DST="/tmp/distribution"
[ -r ${DST} ] && rm -f ${DST}
cat /root/bases/distribution/scan-p1 > ${DST}

sysrc -qf ${DST} full_packages=""

find ${REPO_DIR}/ -type f -name FreeBSD-\*.pkg -print | while read _file; do
	NAME=$( pkg info -F ${_file} |grep ^Name | awk '{printf $3}' )

	truncate -s0 ${DST}.tmp
	tmp=

	echo ">> SCAN FOR ${NAME}.."

	pkg info -l -F ${_file} | while read _path; do
		case "${_path}" in
			/bin/*|/sbin/*|/usr/bin/*|/usr/sbin/*|/usr/libexec/*)
				if [ -z "${tmp}" ]; then
					tmp="${_path}"
				else
					tmp="${tmp} ${_path}"
				fi
				;;
			*)
				continue
				;;
		esac

		[ -n "${tmp}" ] && sysrc -qf ${DST}.tmp tmp="${tmp}" 2>/dev/null 2>&1
	done

	size=$( stat -f %z ${DST}.tmp 2>/dev/null )

	if [ "${size}" != "0" ]; then
		tmp=
		. ${DST}.tmp
		sysrc -qf ${DST} pkg${pkg_num}_path="${tmp}" 2>/dev/null 2>&1
		sysrc -qf ${DST} pkg${pkg_num}_name="${NAME}" 2>/dev/null 2>&1

		tmp1=

		for i in ${tmp}; do
			_basename=$( basename ${i} )
			if [ -n "${tmp1}" ]; then
				tmp1="${tmp1} ${_basename}"
			else
				tmp1="${_basename}"
			fi
		done

		sysrc -qf ${DST} pkg${pkg_num}="${tmp1}" 2>/dev/null 2>&1
		sysrc -qf ${DST} full_packages+="pkg${pkg_num}" 2>/dev/null 2>&1

		pkg_num=$(( pkg_num + 1 ))
	fi

	rm -f ${DST}.tmp
done

cat /root/bases/distribution/scan-p2 >> ${DST}

chmod +x ${DST}
mv ${DST} ${REPO_DIR}/

exit 0
