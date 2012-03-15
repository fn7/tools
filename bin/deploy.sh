#!/bin/sh
TO=$1
FROM=$2
echo "======================================================================="
echo "$FROM -> $TO:~/"
echo "======================================================================="
echo "deploy? [yN]"
read n
if [ x$n = 'xy' ]; then
  tar cfz - $FROM | ssh $TO -C 'tar xvfz -';
  echo "done"
else 
  echo "abort"
fi
