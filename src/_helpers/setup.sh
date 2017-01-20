#!/usr/bin/env bash
set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

export NAME=${1:-$JOB_NAME}
export HOME=${HOME:-/home/vcap}
export BASE_DIR="/var/vcap/jobs/$NAME"
export PACKAGES="$BASE_DIR/packages"

# Setup the PATH and LD_LIBRARY_PATH
LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-''}
for package_dir in $(ls -d $PACKAGES/*); do
  has_busybox=0
  # Add all packages' /bin & /sbin into $PATH
  for package_bin_dir in $(ls -d ${package_dir}/*bin 2>/dev/null); do
    # Do not add any packages that use busybox, as impacts builtin commands and
    # is often used for different architecture (via containers)
    if [ -f ${package_bin_dir}/busybox ]; then
      has_busybox=1
    else
      PATH=${package_bin_dir}:$PATH
    fi
  done
  if [ "$has_busybox" == "0" ]; then
    if [ -d ${package_dir}/lib ]; then
      LD_LIBRARY_PATH="${package_dir}/lib:$LD_LIBRARY_PATH"
    fi
    # Python libs
    for package_lib_dir in $(ls -d ${package_dir}/lib/python*/lib-dynload 2>/dev/null); do
      LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
    done
    for package_lib_dir in $(ls -d ${package_dir}/lib/python*/site-packages 2>/dev/null); do
      LD_LIBRARY_PATH="${package_lib_dir}:${LD_LIBRARY_PATH}"
    done
  fi
done
export PATH
export LD_LIBRARY_PATH

# Python modules
PYTHONPATH=${PYTHONPATH:-''}
for python_mod_dir in $(ls -d $PACKAGES/*/lib/python*/site-packages 2>/dev/null); do
    PYTHONPATH="${python_mod_dir}:${PYTHONPATH}"
done
export PYTHONPATH

# Setup log and tmp folders
export LOG_DIR="/var/vcap/sys/log/$NAME"
mkdir -p "$LOG_DIR" && chmod 775 "$LOG_DIR"

export RUN_DIR="/var/vcap/sys/run/$NAME"
mkdir -p "$RUN_DIR" && chmod 775 "$RUN_DIR"

export TMP_DIR="/var/vcap/sys/tmp/$NAME"
mkdir -p "$TMP_DIR" && chmod 775 "$TMP_DIR"
export TMPDIR="$TMP_DIR"

