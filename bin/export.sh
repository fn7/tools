#!/bin/sh

dir=$1
name=$2

if [ -d $dir ]; then
  URL=`(cd $dir && svn info | grep 'URL')`
  URL=${URL#URL: }
  svn export $URL $name
fi


