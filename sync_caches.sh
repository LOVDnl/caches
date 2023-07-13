#!/bin/bash

# Created  : 2023-07-07
# Modified : 2023-07-12

# Syncs caches with two remote servers.
# This script should be run from our local machine.

echo "Retrieving remote caches...";
for HOST in kg-web01 web01;
do
    # First, retrieve caches.
    RAND="sync_$(echo $RANDOM | md5sum | cut -b 1-10)";
    mkdir $RAND;
    if [ $? -ne 0 ];
    then
        echo "Couldn't create temp directory $RAND.";
        exit 1;
    fi;

    rsync -aq "${HOST}:/home/${USER}/git/caches/NC_cache.txt" \
                     ":/home/${USER}/git/caches/mapping_cache.txt" \
          "/www/git/caches/${RAND}";
    if [ $? -ne 0 ];
    then
        echo "Couldn't download caches from ${HOST}.";
        exit 2;
    fi;
done;

echo "";





# Now, clean caches.
echo "Cleaning NC cache...";
FILES=$(find /www/git/caches -name NC_cache.txt);
cat $FILES | sort | uniq > NC_cache.new.txt;

# The new cache is allowed to be slightly longer or slightly shorter than the original cache.
OLD=$(cat NC_cache.txt | wc -l);
NEW=$(cat NC_cache.new.txt | wc -l);
DIFF=$(calc -dp ${NEW}00 / $OLD | cut -d . -f 1);

if [ "${DIFF}" -ge 99 ] && [ "${DIFF}" -le 101 ];
then
    echo "Overlap between new file and old file ${DIFF}%; accepted.";
else
    echo "New file differs too much from old file; ${DIFF}% overlap.";
    exit 3;
fi;

mv -f NC_cache.new.txt NC_cache.txt;
if [ $? -ne 0 ];
then
    echo "Couldn't overwrite the new cache file.";
    exit 4;
fi;

echo "$FILES" | grep -v caches/NC | xargs rm;
if [ $? -ne 0 ];
then
    echo "Couldn't delete temp files.";
    exit 5;
fi;

echo "";





# Clean the mapping cache, multiple times if needed.
FILES=$(find /www/git/caches -name mapping_cache.txt);
cat $FILES | sort | uniq > mapping_cache.sorted.txt;

while (true);
do
    echo "Cleaning mapping cache...";
    # First, find all the repeated variants.
    cut -f 1 mapping_cache.sorted.txt | uniq -c | grep -vE "^\s+1\s" | awk '{print $2}' > tmp.repeated_vars.txt;

    echo -n "Repeated vars: ";
    cat tmp.repeated_vars.txt | wc -l;

    # Then, for each repeated variant, try to be intelligent about which one to toss.
    cat tmp.repeated_vars.txt | while IFS='' read -r variant;
    do
        matches=$(grep -m2 "${variant}\s" mapping_cache.sorted.txt);
        if [ $(echo "${matches}" | grep -v VV | wc -l) != "0" ];
        then
            # Remove the one that doesn't have an VV mapping.
            # We assume here, that we have verified the cache and
            #  therefore *ALL* variants should have the VV method.
            echo "${matches}" | grep -v VV;
        else
            # So, both have VV. Toss the one without the numberConversion.
            echo "${matches}" | grep -v numberConversion;
        fi
    done > tmp.lines_to_be_deleted.txt

    echo -n "Lines to be deleted: ";
    COUNT=$(cat tmp.lines_to_be_deleted.txt | wc -l);
    echo $COUNT;

    # Check...
    if [ $COUNT -gt 0 ];
    then
        # Finally, take the mapping cache and remove these lines.
        comm -2 -3 mapping_cache.sorted.txt tmp.lines_to_be_deleted.txt > mapping_cache.new.txt

        # The new cache is allowed to be slightly longer or slightly shorter than the original cache.
        OLD=$(cat mapping_cache.txt | wc -l);
        NEW=$(cat mapping_cache.new.txt | wc -l);
        DIFF=$(calc -dp ${NEW}00 / $OLD | cut -d . -f 1);

        if [ "${DIFF}" -ge 99 ] && [ "${DIFF}" -le 101 ];
        then
            echo "Overlap between new file and old file ${DIFF}%; accepted.";
        else
            echo "New file differs too much from old file; ${DIFF}% overlap.";
            exit 6;
        fi;

        # Overwrite the cache.
        mv -f mapping_cache.new.txt mapping_cache.txt
        if [ $? -ne 0 ];
        then
            echo "Couldn't overwrite the new cache file.";
            exit 7;
        fi;
    fi;

    # Clean up.
    rm mapping_cache.sorted.txt tmp.repeated_vars.txt tmp.lines_to_be_deleted.txt

    if [ $COUNT -eq 0 ];
    then
        # We're done!
        break;
    else
        # We'll have to go another round.
        cp -p mapping_cache.txt mapping_cache.sorted.txt
    fi;
done;

echo "$FILES" | grep -v caches/mapping | xargs rm;
if [ $? -ne 0 ];
then
  echo "Couldn't delete temp files.";
  exit 8;
fi;

echo "";





# We should now be done, clean up the temp directories.
find /www/git/caches -type d -empty -name "sync_??????????" | xargs rmdir;
if [ $? -ne 0 ];
then
  echo "Couldn't delete temp directories.";
  exit 9;
fi;





# Pushing caches to the remote servers...
echo "Pushing caches to remote servers...";
for HOST in kg-web01 web01;
do
    rsync -aq                      "/www/git/caches/NC_cache.txt" \
                                   "/www/git/caches/mapping_cache.txt" \
       "${HOST}:/home/${USER}/git/caches/";
    if [ $? -ne 0 ];
    then
        echo "Couldn't push caches to ${HOST}.";
        exit 10;
    fi;
done;

echo "done!";
echo "";
