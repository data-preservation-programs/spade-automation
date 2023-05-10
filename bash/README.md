# Automation in bash

Written by Casey Elliot.

## Prerequisites
- put both bash scripts in same directory as the fil-spid.bash
- have a directory with enough space to download the car files you want to process.
- must have aria2c installed

Note: script does not auto clear mpool for you, you need to do that as needed. For
instance, you may want to wait for the gas fees to come down.

## step 1 reserve X number of deals.
- `./spade-make-reservation.sh <miner-id> <numberofdeals>`
- `./spade-make-reservation.sh f0xxxxxx 32`
  
wait for deals to show up in pending proposals.

## step 2 process the pending proposals.
- `./spade-process-pending.sh <miner-id> <pathtodownloadcarsfiles>`
- `./spade-process-pending.sh f0xxxxxx /path/download/cars`

it checks for messages stuck in mpool, and also checks that there are not more than 32 sealings jobs in PC1 state.  edit the file to adjust.
will just loop on hold while mpool has messages.


