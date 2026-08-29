#!/bin/bash

# tmux status bar system metrics display script
# Shows CPU, Memory, and GPU usage with color-coding

# Color function: returns color code based on percentage
get_color() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        echo "#[fg=red]"
    elif [ "$pct" -ge 60 ]; then
        echo "#[fg=yellow]"
    else
        echo ""
    fi
}

# Reset color to default
reset_color() {
    echo "#[fg=colour240]"
}

# Detect OS (Darwin = macOS, Linux = GNU/Linux)
OS="$(uname -s)"

# Get CPU usage percentage (0-100%)
get_cpu() {
    local cores
    if [ "$OS" = "Darwin" ]; then
        cores=$(sysctl -n hw.ncpu)
    else
        cores=$(nproc)
    fi
    local cpu_pct=$(ps -A -o %cpu | awk -v cores="$cores" '{s+=$1} END {print int(s/cores)}')
    local color=$(get_color "$cpu_pct")
    echo "${color}C:${cpu_pct}%$(reset_color)"
}

# Get Memory usage percentage (0-100%)
get_memory() {
    local mem_pct
    if [ "$OS" = "Darwin" ]; then
        local total=$(sysctl -n hw.memsize)
        local pagesize=$(getconf PAGESIZE)
        mem_pct=$(vm_stat | awk -v total="$total" -v pagesize="$pagesize" '
            /Pages active/ {active=$3}
            /Pages wired/ {wired=$4}
            /Pages occupied by compressor/ {occ=$5}
            END {
                used=(active+wired+occ)*pagesize
                print int(used/total*100)
            }
        ')
    else
        local total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        mem_pct=$(( (total_kb-avail_kb)*100/total_kb ))
    fi
    local color=$(get_color "$mem_pct")
    echo "${color}M:${mem_pct}%$(reset_color)"
}

# Get GPU usage percentage (0-100%)
get_gpu() {
    if [ "$OS" = "Darwin" ]; then
        local gpu_pct=$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | \
            grep "Device Utilization %" | \
            sed 's/.*"Device Utilization %"=\([0-9]*\).*/\1/')

        if [ -n "$gpu_pct" ]; then
            local color=$(get_color "$gpu_pct")
            echo "${color}G:${gpu_pct}%$(reset_color)"
        else
            echo "G:N/A"
        fi
    else
        echo "G:N/A"
    fi
}

# Main: output all metrics in tmux status format
main() {
    local cpu=$(get_cpu)
    local mem=$(get_memory)
    local gpu=$(get_gpu)

    echo "${cpu} ${mem} ${gpu}"
}

main
