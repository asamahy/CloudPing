#!/bin/bash

list_avg=();
list_min=();
list_max=();


# Define the list of Oracle Cloud region endpoints
while IFS= read -r line; do
    endpoints+=(${line//\"/})
done < $1


# Number of pings to send
ping_count=1
# set -x
# Function to ping an endpoint and extract average latency
function ping_endpoint() {
    local endpoint=$1
    echo "Pinging $endpoint..."
    # Perform the ping and extract the average latency
    ping_avg=$(ping -c $ping_count $endpoint | tail -1 | awk -F '/' '{print $5}')
    ping_min=$(ping -c $ping_count $endpoint | tail -1 | awk -F '/' '{print $4}')
    ping_max=$(ping -c $ping_count $endpoint | tail -1 | awk -F '/' '{print $6}')
    ping_loss=$(ping -c $ping_count $endpoint | tail -2 | head -1 | awk '{print $7}')

    # ping_avg="48.9"
    # ping_min="41.9"
    # ping_max="55.9"

    # Check if the ping was successful
    if [ -z "$ping_avg" ]; then
        echo "Failed to ping $endpoint or no response."
        # remove the endpoint from the list
        endpoints=(${endpoints[@]//$endpoint})
    else
        list_avg+=($ping_avg);
        list_min+=(${ping_min##* });
        # list_max+=($ping_max);
        list_max+=($ping_max);
        list_loss+=($ping_loss);
    fi
}

# Loop through each endpoint and ping it
for endpoint in "${endpoints[@]}"; do
    ping_endpoint $endpoint
done
pad=$(printf '%0.1s' "-"{1..50})
padlength=50
printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 20 "$pad" 10 "----------" 10 "----------" 10 "----------" 10 "----"
printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 50 "Endpoint" 10 "Average" 10 "Min" 10 "Max" 10 "Loss"
printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 20 "$pad" 10 "----------" 10 "----------" 10 "----------" 10 "----"
for ((i=0; i<${#endpoints[@]}; i++)); do
    printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 50 "${endpoints[$i]}" 10 "${list_avg[$i]}" 10 "${list_min[$i]}" 10 "${list_max[$i]}" 10 "${list_loss[$i]}"
done
