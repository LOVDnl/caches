#!/bin/bash

echo -n "Mapping cache size: ";
cat mapping_cache.txt | wc -l;

# This only works with your cache *sorted*.
cat mapping_cache.txt | sort > mapping_cache.sorted.txt

# First, find all the repeated variants.
cut -f 1 mapping_cache.sorted.txt | uniq -c | grep -vE "^\s+1\s" | awk '{print $2}' > tmp.repeated_vars.txt

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
LINES=$(cat tmp.lines_to_be_deleted.txt | wc -l);
echo $LINES;

# Check...
if [ $LINES -gt "0" ];
then
    less tmp.lines_to_be_deleted.txt;

    # Finally, take the mapping cache and remove these lines.
    comm -2 -3 mapping_cache.sorted.txt tmp.lines_to_be_deleted.txt > mapping_cache.new.txt

    # Check...
    # diff -u mapping_cache.txt mapping_cache.new.txt | less -SM

    # Overwrite the cache.
    mv mapping_cache.new.txt mapping_cache.txt
fi;

# And done.
rm mapping_cache.sorted.txt tmp.repeated_vars.txt tmp.lines_to_be_deleted.txt

echo -n "Mapping cache size: ";
cat mapping_cache.txt | wc -l;

