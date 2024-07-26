#!/bin/bash

list_avg=();
list_min=();
list_max=();
ping_count=$2 # Number of pings to send to each endpoint

# Define the list of Oracle Cloud region endpoints
# read the endpoints from the file
while IFS= read -r line; do
    # endpoints+=(${line//\"/})
    region_name+=("$(echo $line | awk -F',' '{print$1}')");
    endpoints+=("$(echo $line | awk -F',' '{print$2}')");
done < $1


# Number of pings to send to each endpoint (default is 3)
if [ -z $ping_count ] || [ $ping_count == '-' ]; then
    ping_count=1
fi


# set -x
# Function to ping an endpoint and extract average latency
function ping_endpoint() {
    local endpoint=$1
    echo "Pinging $endpoint..."
    # Perform the ping and extract the average latency from the output using awk.
    # the output of the ping command is saved in a variable. The last line of the output is used to extract the required values using awk.
    result=$(ping -c $ping_count $endpoint)
    ping_min=$(echo "$result" | tail -1 | awk -F '/' '{print $4}')
    ping_avg=$(echo "$result" | tail -1 | awk -F '/' '{print $5}')
    ping_max=$(echo "$result" | tail -1 | awk -F '/' '{print $6}')
    ping_loss=$(echo "$result" | tail -2 | head -1 | awk '{print $7}')

    # Check if the ping was successful and the average is used as an indicator of success. If the ping was not successful, the endpoint is removed from the list.
    if [ -z "$ping_avg" ]; then
        echo "Failed to ping $endpoint or no response."
        # remove the endpoint from the list
        endpoints=(${endpoints[@]//$endpoint})
    else # Add each value to the its respective list
        list_avg+=($ping_avg);
        list_min+=(${ping_min##* }); # remove the first part of the string to get the min value
        list_max+=($ping_max);
        list_loss+=($ping_loss);
    fi
}

# Loop through each endpoint and ping it
for endpoint in "${endpoints[@]}"; do
    ping_endpoint $endpoint
done

pad=$(printf '%0.1s' "-"{1..50}) # Create a string of 50 dashes
padlength=50 # Length of the padding string
# Write the header to the report file using printf to format the output in a table format with columns 
# this prinf command uses %-*s to specify the width of each column and the - flag to left-align the text in each column.
# the * is used to specify the width of the column. and the s is used to specify that the value is a string.
printf "%-*s + %-*s + %-*s + %-*s + %-*s\n" 20 "$pad" 10 "----------" 10 "----------" 10 "----------" 10 "----" > report.txt 
printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 50 "Endpoint" 10 "Average" 10 "Min" 10 "Max" 10 "Loss" >> report.txt
printf "%-*s + %-*s + %-*s + %-*s + %-*s\n" 20 "$pad" 10 "----------" 10 "----------" 10 "----------" 10 "----" >> report.txt
for ((i=0; i<${#endpoints[@]}; i++)); do
    printf "%-*s | %-*s | %-*s | %-*s | %-*s\n" 50 "${endpoints[$i]}" 10 "${list_avg[$i]}" 10 "${list_min[$i]}" 10 "${list_max[$i]}" 10 "${list_loss[$i]}" >> report.txt # Write each endpoint and its corresponding values to the report file.
done

# display the report file
cat report.txt
