#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <MINER_ID> <NumToReserve>"
  exit 1
fi

set -eu
set -o pipefail

miner=$1
limit=$2

# make reserve API call and store response in variable
response=$(curl -sLH "Authorization: $( ./fil-spid.bash $miner )" https://api.spade.storage/sp/eligible_pieces?limit=$limit)

# get response code from JSON output
response_code=$(echo $response | jq -r '.response_code')
response_entries=$(echo $response | jq -r '.response_entries')

# if response code is 200, execute the sample_reserve_cmd from the JSON output
if [ $response_code -eq 200 ]; then
	for (( i=0; i<$response_entries; i++ ))
	do
  	   echo "Processing entry: $i"
  		piece_cid=$(echo $response | jq -r --argjson idx "$i" '.response[$idx].piece_cid')
  		sample_reserve_cmd=$(echo $response | jq -r --argjson idx "$i" '.response[$idx].sample_reserve_cmd' | sed 's/"/\\\"/g' | sed 's/\\$/\\\\$/g')
  		echo "Qualifying Piece CID: $piece_cid"
  		echo "Executing sample_reserve_cmd... $sample_reserve_cmd"
  		eval $sample_reserve_cmd
	done

else
  echo "Error: response code $response_code"
fi

echo "Made $response_entries reservations! Next Step is to check pending proposals"
