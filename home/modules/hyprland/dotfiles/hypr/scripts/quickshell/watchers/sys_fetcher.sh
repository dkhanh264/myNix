#!/usr/bin/env bash

# 1. Read initial values for time-sensitive metrics (CPU and Network)
read -r u1 n1 s1 i1 io1 ir1 so1 st1 g1 gn1 < <(awk '/^cpu /{print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11; exit}' /proc/stat)
read rx1 tx1 <<< "$(awk -v IGNORECASE=1 '/^ *[ew]/{rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev)"

# 2. Small delay to calculate precise usage deltas
sleep 0.5

# 3. Read final values
read -r u2 n2 s2 i2 io2 ir2 so2 st2 g2 gn2 < <(awk '/^cpu /{print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11; exit}' /proc/stat)
read rx2 tx2 <<< "$(awk -v IGNORECASE=1 '/^ *[ew]/{rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev)"

# --- CPU Calculation ---
IDLE1=$i1; TOTAL1=$((u1 + n1 + s1 + i1 + io1 + ir1 + so1 + st1))
IDLE2=$i2; TOTAL2=$((u2 + n2 + s2 + i2 + io2 + ir2 + so2 + st2))
DIFF_IDLE=$((IDLE2 - IDLE1))
DIFF_TOTAL=$((TOTAL2 - TOTAL1))
if [ "$DIFF_TOTAL" -eq 0 ]; then CPU_USAGE=0; else CPU_USAGE=$(( 100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL )); fi

# --- Network Calculation ---
# Bytes across 0.5 seconds multiplied by 2 = Bytes per second
RX_RATE=$(((rx2 - rx1) * 2))
TX_RATE=$(((tx2 - tx1) * 2))

# --- RAM Calculation ---
read -r TOTAL_MEM AVAIL_MEM RAM_PCT RAM_GB < <(
    awk '
        /^MemTotal:/     { total=$2 }
        /^MemAvailable:/ { avail=$2 }
        END {
            used = total - avail
            if (total <= 0) {
                printf "0 0 0 0.0\n"
            } else {
                printf "%d %d %d %.1f\n", total, avail, (100 * used / total), (used / 1048576)
            }
        }
    ' /proc/meminfo
)

# --- Temperature Calculation ---
: "${QS_CACHE_SYSDATA:=/tmp/quickshell/sysdata}"
mkdir -p "$QS_CACHE_SYSDATA"
TEMP_PATH_FILE="${QS_CACHE_SYSDATA}/temp_path"

resolve_temp_path() {
    local hwmon hwmon_name tz tz_type

    for hwmon in /sys/class/hwmon/hwmon*; do
        [ -r "$hwmon/name" ] || continue
        read -r hwmon_name < "$hwmon/name" || continue
        case "$hwmon_name" in
            coretemp|k10temp|zenpower|cpu_thermal|bcm2835_thermal)
                if [ -r "$hwmon/temp1_input" ]; then
                    printf '%s\n' "$hwmon/temp1_input"
                    return
                fi
                ;;
        esac
    done

    for tz in /sys/class/thermal/thermal_zone*; do
        [ -r "$tz/type" ] || continue
        read -r tz_type < "$tz/type" || continue
        case "$tz_type" in
            x86_pkg_temp|cpu_thermal|cpu-thermal)
                if [ -r "$tz/temp" ]; then
                    printf '%s\n' "$tz/temp"
                    return
                fi
                ;;
        esac
    done

    [ -r /sys/class/hwmon/hwmon0/temp1_input ] && { printf '%s\n' "/sys/class/hwmon/hwmon0/temp1_input"; return; }
    [ -r /sys/class/thermal/thermal_zone0/temp ] && { printf '%s\n' "/sys/class/thermal/thermal_zone0/temp"; return; }
}

get_temp_raw() {
    local temp_path="" raw_temp=0

    if [ -r "$TEMP_PATH_FILE" ]; then
        read -r temp_path < "$TEMP_PATH_FILE" || temp_path=""
    fi

    if [ -z "$temp_path" ] || [ ! -r "$temp_path" ]; then
        temp_path="$(resolve_temp_path)"
        if [ -n "$temp_path" ]; then
            printf '%s\n' "$temp_path" > "$TEMP_PATH_FILE"
        else
            rm -f "$TEMP_PATH_FILE"
        fi
    fi

    if [ -n "$temp_path" ] && [ -r "$temp_path" ]; then
        read -r raw_temp < "$temp_path" || raw_temp=0
    fi

    printf '%s\n' "${raw_temp:-0}"
}

TEMP_RAW="$(get_temp_raw)"

# Normalize to degrees Celsius
if [ "$TEMP_RAW" -gt 1000 ]; then
    TEMP=$((TEMP_RAW / 1000))
else
    TEMP=$TEMP_RAW
fi

# --- Output formatted string ---
# Format: CPU|RAM_PCT|RAM_GB|TEMP|RX_RATE|TX_RATE
echo "$CPU_USAGE|$RAM_PCT|$RAM_GB|$TEMP|$RX_RATE|$TX_RATE"
