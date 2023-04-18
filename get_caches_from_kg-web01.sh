#!/bin/bash

echo "This will overwrite the local caches. Are you sure?";
read;

rsync -av ifokkema@kg-web01:/home/ifokkema/git/caches/NC_cache.txt :/home/ifokkema/git/caches/mapping_cache.txt /www/git/caches/

