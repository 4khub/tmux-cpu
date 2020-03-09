#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

mem_percentage_format="%3.1f%%"

calc() {
    local stdin;
    read -d '' -u 0 stdin;
    awk "BEGIN { print $stdin  }";
}

print_mem() {
  mem_percentage_format=$(get_tmux_option "@mem_percentage_format" "$mem_percentage_format")

  local mem_usage
  
  if is_osx; then
    mem_usage=$(get_mem_usage_osx)
  elif is_linux; then 
    mem_usage=$(get_mem_usage_linux)
  elif is_freebsd; then
    mem_usage=$(get_mem_usage_freebsd)
  fi

  # Extract free and used memory in MiB, calculate total and percentage
  local mem_free=$(echo $mem_usage | awk '{ print $1 }')
  local mem_used=$(echo $mem_usage | awk '{ print $2 }')
  local mem_total=$(echo "$mem_free + $mem_used" | calc)
  local mem_pused=$(echo "($mem_used / $mem_total) * 100" | calc)
  local mem_pfree=$(echo "($mem_free / $mem_total) * 100" | calc)

  echo "$mem_pused" | awk -v format="$mem_percentage_format" '{printf format, $1}'
}


# Report like it does htop on OSX:
# used = active + wired
# free = free + inactive + speculative + occupied by compressor
# see `vm_stat` command
get_mem_usage_osx(){
  
  local page_size=$(sysctl -nq "vm.pagesize")
  vm_stat | awk -v page_size=$page_size -F ':' '
    BEGIN { free=0; used=0 }
    
    /Pages active/ || 
    /Pages wired/ { 
      gsub(/^[ \t]+|[ \t]+$/, "", $2); used+=$2;
    }
    /Pages free/ || 
    /Pages inactive/ || 
    /Pages speculative/ || 
    /Pages occupied by compressor/ { 
      gsub(/^[ \t]+|[ \t]+$/, "", $2); free+=$2;
    }
    END { print (free * page_size)/1024, (used * page_size)/1024 }
  '
}

# Relies on vmstat, but could also be done with top on FreeBSD
get_mem_usage_freebsd(){
  vmstat -H | tail -n 1 | awk '{ print $5, $4 }'
}

# Method #1. Sum up free+buffers+cached, treat it as "available" memory, assuming buff+cache can be reclaimed. Note, that this assumption is not 100% correct, buff+cache most likely cannot be 100% reclaimed, but this is how memory calculation is used to be done on Linux

# Method #2. If "MemAvailable" is provided by system, use it. This is more correct method, because we're not relying on fragile "free+buffer+cache" equation. 

# See: Interpreting /proc/meminfo and free output for Red Hat Enterprise Linux 5, 6 and 7 - Red Hat Customer Portal - https://access.redhat.com/solutions/406773

# See: kernel/git/torvalds/linux.git - /proc/meminfo: provide estimated available memory - https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=34e431b0ae398fc54ea69ff85ec700722c9da773
get_mem_usage_linux(){
  </proc/meminfo awk '
    BEGIN { total=0; free=0; }
      /MemTotal:/ { total=$2; }
      
      /MemFree:/ { free+=$2; }
      /Buffers:/ { free+=$2; }
      /Cached:/ { free+=$2; }
      /MemAvailable:/ { free=$2; exit;}
    END { print free, total-free }
  '
}

main() {
  print_mem
}

main
