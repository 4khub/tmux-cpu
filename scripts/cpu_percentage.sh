#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

cpu_percentage_format="%.2f"

cpus_number() {
  if is_linux; then
    nproc
  else
    sysctl -n hw.ncpu
  fi
}

print_cpu_percentage() {
  cpu_percentage_format=$(get_tmux_option "@cpu_percentage_format" "$cpu_percentage_format")

  if command_exists "iostat"; then
    if is_linux_iostat; then
      iostat -c 1 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=1.0-$NF/100.0} END {printf(format, usage)}' | sed 's/,/./'
    elif is_osx; then
      iostat -c 2 disk0 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=1.0-$6/100.0} END {printf(format, usage)}' | sed 's/,/./'
    elif is_freebsd || is_openbsd; then
      iostat -c 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=1.0-$NF/100.0} END {printf(format, usage)}' | sed 's/,/./'
    else
      echo "unknown iostat version please create an issue"
    fi
  elif command_exists "sar"; then
    sar -u 1 1 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=1.0-$NF/100.0} END {printf(format, usage)}' | sed 's/,/./'
  else
    load=`ps -aux | awk '{print $3}' | tail -n+2 | awk '{s+=$1} END {print s}'`
    cpus=$(cpus_number)
    echo "$load $cpus" | awk -v format="$cpu_percentage_format" '{printf format, $1/$2/100.0}'
  fi
}

main() {
  print_cpu_percentage
}
main
