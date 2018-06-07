#!/bin/bash

set -euo pipefail

dir=$1
test_tmpdir=$(pwd)

cd ${dir}
env PYTHONUNBUFFERED=1 setsid python -m SimpleHTTPServer 0 >${test_tmpdir}/httpd-output &
child_pid=$!

for x in $(seq 50); do
    # Snapshot the output
    cp ${test_tmpdir}/httpd-output{,.tmp}
    sed -ne 's/^/# httpd-output.tmp: /' < ${test_tmpdir}/httpd-output.tmp >&2
    echo >&2
    # If it's non-empty, see whether it matches our regexp
    if test -s ${test_tmpdir}/httpd-output.tmp; then
        sed -e 's,Serving HTTP on 0.0.0.0 port \([0-9]*\) \.\.\.,\1,' < ${test_tmpdir}/httpd-output.tmp > ${test_tmpdir}/httpd-port
        if ! cmp ${test_tmpdir}/httpd-output.tmp ${test_tmpdir}/httpd-port 1>/dev/null; then
            # If so, we've successfully extracted the port
            break
        fi
    fi
    sleep 0.1
done
port=$(cat ${test_tmpdir}/httpd-port)
echo "http://127.0.0.1:${port}" > ${test_tmpdir}/httpd-address
echo "$child_pid" > ${test_tmpdir}/httpd-pid
