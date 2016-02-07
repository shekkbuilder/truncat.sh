#! /bin/bash
# truncat.sh
# Adapted from @BobC's script http://superuser.com/a/836950/539429
#
# Efficiently cat log files that have been previously truncated.  
# They are sparse -- many null blocks before the interesting content.
# This script skips the null blocks in bulk (except for the last) 
# and then uses tr to filter the remaining nulls.
#
for f in $@; do
  fields=( `stat -c "%o %B %b %s" $f` )
  xfer_block_size=${fields[0]}
  alloc_block_size=${fields[1]}
  blocks_alloc=${fields[2]}
  size_bytes=${fields[3]}

  bytes_alloc=$(( $blocks_alloc * $alloc_block_size ))

  alloc_in_xfer_blocks=$(( ($bytes_alloc + ($xfer_block_size - 1))/$xfer_block_size ))
  size_in_xfer_blocks=$(( ($size_bytes + ($xfer_block_size - 1))/$xfer_block_size ))
  null_xfer_blocks=$(( $size_in_xfer_blocks - $alloc_in_xfer_blocks ))
  null_xfer_bytes=$(( $null_xfer_blocks * $xfer_block_size ))
  non_null_bytes=$(( $size_bytes - $null_xfer_bytes ))

  if [ "$non_null_bytes" -gt "0" -a "$non_null_bytes" -lt "$size_bytes" ]; then
    cmd="dd if=$f ibs=$xfer_block_size obs=8M skip=$null_xfer_blocks "
    $cmd | tr -d "\000"
  else
    cat $f
  fi
done
