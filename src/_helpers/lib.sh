#!/usr/bin/env bash
set -e # exit immediately if a simple command exits with a non-zero status
set -u # report the usage of uninitialized variables

# Global configuration settings for this lib
export JOB_ANSIBLE_DIR="ansible"
export JOB_ANSIBLE_INVENTORY="inventory"
export JOB_ANSIBLE_ENV="env.sh"
export JOB_ANSIBLE_EXEC="/var/vcap/packages/ansible/bin/ansible-playbook"

# Python dlopen does not pay attention to LD_LIBRARY_PATH, so
# ctypes.util.find_library is not able to find dyn libs, the only
# way to do is by defining the folders in ldconfig
function ldconf {
    local path="${1}"

    echo "$path" | tr ':' '\n' > $TMP_DIR/ld.so.conf
    ldconfig -f $TMP_DIR/ld.so.conf
    rm -f $TMP_DIR/ld.so.conf
}


# Get a list of playbooks from all jobs by lexical order
function get_playbooks {
    local base_path="${1}"
    local name="${2}"

    local playbooks=()
    for playbook in $(find -L "${base_path}" -path "*/$JOB_ANSIBLE_DIR/${name}"); do
        local playbook_name="${playbook##*/}"
        # insert the element in the ordered array playbooks
        local length=${#playbooks[@]}
        if [[ $length == 0 ]]; then
            playbooks=("${playbook}")
        else
            local item
            local position=-1
            for (( i=0; i<=$(( $length - 1 )); i++ )); do
                item="${playbooks[$i]%%:*}"
                if [[ "${playbook_name}" < "${item##*/}" ]]; then
                    playbooks=("${playbooks[@]:0:$i}" "${playbook}" "${playbooks[@]:$i}")
                    position=$i
                    break
                fi
            done
            if (( $position < 0 )); then
                # not inserted, append
                playbooks+=("${playbook}")
            fi
        fi
    done
    if [[ ${#playbooks[@]} > 0 ]]; then
        echo "${playbooks[@]}"
    fi
}


# Exec an ansible from other job ansible folder
function run_playbook {
    local kind="${1}"
    local playbook="${2}"
    local params="${@:3}"

    local pid
    local logfile="${LOG_DIR}/${kind}.log"
    local playbook_name="${playbook##*/}"
    local playbook_path="${playbook%/*}"
    (
        # Inventory and other variables can be overwritten by the file env.sh
        [ -e "${playbook_path}/$JOB_ANSIBLE_INVENTORY" ] && params="${params} -i ${playbook_path}/$JOB_ANSIBLE_INVENTORY"
        [ -e "${playbook_path}/$JOB_ANSIBLE_ENV" ] && source "${playbook_path}/$JOB_ANSIBLE_ENV"
        proc="$JOB_ANSIBLE_EXEC ${params} ${playbook}"
        echo "* -- START $(date) --" >> "${logfile}"
        env >> "${logfile}"
        {
            echo "* $$: ${proc}"
            exec ${proc} 2>&1;
        } >> "${logfile}"
    ) &
    pid=$!
    wait $pid 2>/dev/null
    rvalue=$?
    echo "* -- END $pid -- RC=$rvalue" >> "$logfile"
    return $rvalue
}


# Execute all
function run_all {
    local base_dir="${1}"
    local playbooktype="${2}"
    local playbookname="${3}"
    local variables="${@:4}"

    local error=0
    local params
    [ -z "$variables" ] && params='' || params="--extra-vars '${variables}'"
    # Search for playbooks
    for playbook in $(get_playbooks "${base_dir}" "${playbookname}"); do
        run_playbook "${playbooktype}" "${playbook}" ${params}
        rvalue=$?
        [ $rvalue != 0 ] && error=$rvalue
    done
    # Return error if any of the playbooks failed
    return $error
}

