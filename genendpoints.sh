#!/bin/bash

# generate a ping list for use pinglist.sh
# input is a csv file created from tha table on the Oracle Resources page (just copy paste into excel and save as csv)
# the list created contains the region name and an endpoint using the region identifier
#######
while read -r line; do                                     
region_name+=("$(echo $line | awk -F',' '{print$1}')");
region_id+=("$(echo $line | awk -F',' '{print$2}')");
done < $1

i=1;\
for region in "${region_name[@]:1}"; do
echo ${region}\,objectstorage\.${region_id[$i]}\.oraclecloud\.com >> endpoints.txt;
((i++));
done;