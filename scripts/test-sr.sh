#!/bin/bash

set -e -u

# stolen from zfs/scripts/common.sh
function populate
{
        local ROOT=$1
        local MAX_DIR_SIZE=$2
        local MAX_FILE_SIZE=$3

        mkdir -p $ROOT/{a,b,c,d,e,f,g}/{h,i}
        local DIRS=`find $ROOT`

        for DIR in $DIRS; do
                local COUNT=$(($RANDOM % $MAX_DIR_SIZE))

                local i
                for i in `seq $COUNT`; do
                        local FILE=`mktemp -p ${DIR}`
                        local SIZE=$(($RANDOM % $MAX_FILE_SIZE))
                        dd if=/dev/urandom of=$FILE bs=1k count=$SIZE &>/dev/null
                done
        done

        return 0
}

for p in pool1 pool2
do
	zpool list ${p} >& /dev/null || continue
	echo 2>&1 "${p} exists: are you sure you want to do this??"
	exit 1
done

echo "creating pool1, pool2"
rm -f /var/tmp/pool{1,2}-vdev{0..3}
truncate -s 256M /var/tmp/pool{1,2}-vdev{0..3}
zpool create pool1 /var/tmp/pool1-vdev{0..3}
zpool create pool2 /var/tmp/pool2-vdev{0..3}
zfs set atime=off pool1
zfs set atime=off pool2

zfs create pool1/fs
zfs set snapdev=visible pool1/fs

[ -e /tmp/${0}.data ] || populate /tmp/${0}.data 10 100

declare -i i=0

# basic
i+=1
echo "test ${i}"
cp -RL /tmp/${0}.data /pool1/fs/${i}
zfs snapshot pool1/fs@snap${i}
zfs send pool1/fs@snap${i} | zfs receive pool2/fs
diff -qr /pool1/fs /pool2/fs || { echo 1>&2 "Bad compare from test $i"; exit 1; }

# incremental
i+=1
echo "test ${i}"
cp -RL /tmp/${0}.data /pool1/fs/${i}
zfs snapshot pool1/fs@snap${i}
zfs send -i pool1/fs@snap$((i - 1)) pool1/fs@snap${i} | zfs receive pool2/fs
diff -qr /pool1/fs /pool2/fs || { echo 1>&2 "Bad compare from test $i"; exit 1; }

# incremental -F
i+=1
echo "test ${i}"
cp -RL /tmp/${0}.data /pool1/fs/${i}
zfs snapshot pool1/fs@snap${i}

touch /pool2/fs/file

zfs send -i pool1/fs@snap$((i - 1)) pool1/fs@snap${i} | zfs receive -F pool2/fs

diff -qr /pool1/fs /pool2/fs || { echo 1>&2 "Bad compare from test $i"; exit 1; }

exit 0
