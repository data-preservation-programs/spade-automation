#!/bin/bash

if [[ -z "$1" || -z "$2" ]]; then
  echo "Usage: $0 <MINER_ID> <Path to store cars>"
  exit 1
fi
#check that path exists, remove trailing slash if present
if [ -d $2 ]
   then
        echo "$2 is valid path"
        downloadDirectory="${2%/}"
        echo "using $downloadDirectory as download directory."
   else
        echo "$2 is not a valid path"
	exit 1
fi

set -eu
set -o pipefail

miner=$1
MAXPC1=32
SLEEPJOBCHECK=15
SEALINGJOBSTYPES="PC1\|RU\|GET\|FRU\|AP"

check_mpool(){
        mps=$(lotus mpool pending --local | wc -l)
        echo checking mpool for msgs, found "$mps"
        while [ "$mps" -gt 0 ]
        do
                echo "Found msgs in mpool sleep 15 seconds... consider running: lotus mpool replace --auto --fee-limit <amount> <address> <nounce>"
                sleep 15
                mps=$(lotus mpool pending --local | wc -l)
        	echo checking mpool for msgs, found "$mps"
        done
}
check_jobs(){
        PC1s=$(lotus-miner sealing jobs | grep -c "$SEALINGJOBSTYPES")
        echo "Checking Sealing jobs! Found $PC1s, Max set to $MAXPC1 ."
        while [ "$PC1s" -gt $MAXPC1 ]
        do
                echo "to many Sealing Jobs to contintue sleeping for $SLEEPJOBCHECK seconds..."
                sleep $SLEEPJOBCHECK
                PC1s=$(lotus-miner sealing jobs | grep -c "$SEALINGJOBSTYPES")
                echo "Checking RU jobs! Found $PC1s, Max set to $MAXPC1."
        done
}


pending_response=$(echo curl -sLH \"Authorization: $( ./fil-spid.bash "$miner" )\" https://api.spade.storage/sp/pending_proposals | sh)

# get response code from JSON output
pending_response_code=$(echo "$pending_response" | jq -r '.response_code')
pending_proposals=$(echo "$pending_response" | jq -r '.response.pending_proposals')
pending_count=$(echo "$pending_proposals" | grep -c "sample_import_cmd" )
echo "$pending_response"
echo "API response code found: $pending_response_code"
echo "API pending proposals found: $pending_proposals"
echo "Pending Proposals count :$pending_count"

# if response code is 200
if [ "$pending_response_code" -eq 200 ]; then
                for (( i=0; i<$pending_count; i++ ))
                do
			check_mpool
			check_jobs
                        echo "Processing entry: $i"
                        dl=$(echo "$pending_response" | jq -r --argjson idx "$i" '.response.pending_proposals[$idx].data_sources[0]')
                        deal_proposal_cid=$(echo "$pending_response" | jq -r --argjson idx "$i" '.response.pending_proposals[$idx].deal_proposal_cid')
                        piece_cid=$(echo "$pending_response" | jq -r --argjson idx "$i" '.response.pending_proposals[$idx].piece_cid')
			f=$(basename -- "$dl")
			echo "found Deal: $deal_proposal_cid"
			echo "found Download URL: $dl"
			echo "found Piece CID: $piece_cid"
			echo "found carfile: $f"
			if [ -e "$downloadDirectory/""$f".aria2 ]; then
    			   echo "Parital File exist resume download it..."
			   aria2c -d "$downloadDirectory" "$dl" -j1 -x5 --auto-file-renaming=false 
			   boostd import-data "$deal_proposal_cid" "$downloadDirectory/""$f"
			   # echo "boostd import-data "$deal_proposal_cid" "$downloadDirectory/""$f""
			elif [ -e "$downloadDirectory/""$f" ]; then
			    echo "$f File already exists, assuming it has already been imported! copy and paste the next line if you need to import."
			    echo "boostd import-data "$deal_proposal_cid" "$downloadDirectory/""$f""
			else
    			   echo "File does not exist download it..."
			   aria2c -d "$downloadDirectory" "$dl" -j1 -x5 --auto-file-renaming=false 
			   boostd import-data "$deal_proposal_cid" "$downloadDirectory/""$f"
			   # echo "boostd import-data "$deal_proposal_cid" "$downloadDirectory/""$f""
			fi
                done
else
  echo "Error: response code $pending_response_code"
fi

