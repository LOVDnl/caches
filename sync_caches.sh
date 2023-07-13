#!/bin/bash

# Created  : 2023-07-07
# Modified : 2023-07-12

# Syncs caches with two remote servers.
# This script should be run from our local machine.

DIR="$(dirname $0)";
echo "Retrieving remote caches...";
for HOST in kg-web01 web01;
do
    # First, retrieve caches.
    RAND="sync_$(echo $RANDOM | md5sum | cut -b 1-10)";
    mkdir "${DIR}/${RAND}";
    if [ $? -ne 0 ];
    then
        echo "Couldn't create temp directory $RAND.";
        exit 1;
    fi;

    rsync -aq "${HOST}:/home/${USER}/git/caches/NC_cache.txt" \
                     ":/home/${USER}/git/caches/mapping_cache.txt" \
                     "${DIR}/${RAND}";
    if [ $? -ne 0 ];
    then
        echo "Couldn't download caches from ${HOST}.";
        exit 2;
    fi;
done;

echo "";





# Now, clean caches.
echo "Cleaning NC cache...";
FILES=$(find "${DIR}" -name NC_cache.txt);
cat $FILES | sort | uniq > "${DIR}/NC_cache.new.txt";

# The new cache is allowed to be slightly longer or slightly shorter than the original cache.
OLD=$(cat "${DIR}/NC_cache.txt" | wc -l);
NEW=$(cat "${DIR}/NC_cache.new.txt" | wc -l);
DIFF=$(calc -dp ${NEW}00 / $OLD | cut -d . -f 1);

if [ "${DIFF}" -ge 99 ] && [ "${DIFF}" -le 101 ];
then
    echo "Overlap between new file and old file ${DIFF}%; accepted.";
else
    echo "New file differs too much from old file; ${DIFF}% overlap.";
    exit 3;
fi;

mv -f "${DIR}/NC_cache.new.txt" "${DIR}/NC_cache.txt";
if [ $? -ne 0 ];
then
    echo "Couldn't overwrite the new cache file.";
    exit 4;
fi;

# grep needs an -F in case DIR is "./".
echo "$FILES" | grep -vF "${DIR}/NC" | xargs rm;
if [ $? -ne 0 ];
then
    echo "Couldn't delete temp files.";
    exit 5;
fi;

echo "";





# Clean the mapping cache, multiple times if needed.
FILES=$(find "${DIR}" -name mapping_cache.txt);
cat $FILES | sort | uniq > "${DIR}/mapping_cache.sorted.txt";

while (true);
do
    echo "Cleaning mapping cache...";
    # First, find all the repeated variants.
    cut -f 1 "${DIR}/mapping_cache.sorted.txt" | uniq -c | grep -vE "^\s+1\s" | awk '{print $2}' > "${DIR}/tmp.repeated_vars.txt";

    echo -n "Repeated vars: ";
    cat "${DIR}/tmp.repeated_vars.txt" | wc -l;

    # Then, for each repeated variant, try to be intelligent about which one to toss.
    cat "${DIR}/tmp.repeated_vars.txt" | while IFS='' read -r variant;
    do
        matches=$(grep -m2 "${variant}\s" "${DIR}/mapping_cache.sorted.txt");
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
    done > "${DIR}/tmp.lines_to_be_deleted.txt";

    echo -n "Lines to be deleted: ";
    COUNT=$(cat "${DIR}/tmp.lines_to_be_deleted.txt" | wc -l);
    echo $COUNT;

    # Check...
    if [ $COUNT -gt 0 ];
    then
        # Finally, take the mapping cache and remove these lines.
        comm -2 -3 "${DIR}/mapping_cache.sorted.txt" "${DIR}/tmp.lines_to_be_deleted.txt" > "${DIR}/mapping_cache.new.txt";

        # The new cache is allowed to be slightly longer or slightly shorter than the original cache.
        OLD=$(cat "${DIR}/mapping_cache.txt" | wc -l);
        NEW=$(cat "${DIR}/mapping_cache.new.txt" | wc -l);
        DIFF=$(calc -dp ${NEW}00 / $OLD | cut -d . -f 1);

        if [ "${DIFF}" -ge 99 ] && [ "${DIFF}" -le 101 ];
        then
            echo "Overlap between new file and old file ${DIFF}%; accepted.";
        else
            echo "New file differs too much from old file; ${DIFF}% overlap.";
            exit 6;
        fi;

        # Overwrite the cache.
        mv -f "${DIR}/mapping_cache.new.txt" "${DIR}/mapping_cache.txt";
        if [ $? -ne 0 ];
        then
            echo "Couldn't overwrite the new cache file.";
            exit 7;
        fi;
    fi;

    # Clean up.
    rm "${DIR}/mapping_cache.sorted.txt" "${DIR}/tmp.repeated_vars.txt" "${DIR}/tmp.lines_to_be_deleted.txt";

    if [ $COUNT -eq 0 ];
    then
        # We're done!
        break;
    else
        # We'll have to go another round.
        cp -p "${DIR}/mapping_cache.txt" "${DIR}/mapping_cache.sorted.txt";
    fi;
done;

# grep needs an -F in case DIR is "./".
echo "$FILES" | grep -vF "${DIR}/mapping" | xargs rm;
if [ $? -ne 0 ];
then
  echo "Couldn't delete temp files.";
  exit 8;
fi;

echo "";





# We should now be done, clean up the temp directories.
find "${DIR}" -type d -empty -name "sync_??????????" | xargs rmdir;
if [ $? -ne 0 ];
then
  echo "Couldn't delete temp directories.";
  exit 9;
fi;





# Pushing caches to the remote servers...
echo "Pushing caches to remote servers...";
for HOST in kg-web01 web01;
do
    rsync -aq "${DIR}/NC_cache.txt" \
              "${DIR}/mapping_cache.txt" \
       "${HOST}:/home/${USER}/git/caches/";
    if [ $? -ne 0 ];
    then
        echo "Couldn't push caches to ${HOST}.";
        exit 10;
    fi;
done;

echo "done!";
echo "";
