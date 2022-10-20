#!/bin/sh

BASE=`echo $1 | sed 's,^\.,,g'`
LOCAL=`echo $2 | sed 's,^\.,,g'`
REMOTE=`echo $3 | sed 's,^\.,,g'`
#MERGED=`echo $4 | sed 's,^\.,,g'`
MERGED=`echo $4`

case "$BASE"
in
    *)
    B=$(echo `git rev-parse --show-toplevel`/"$BASE" | sed 's,/d/,D:/,g' | sed 's,/,\\\\,g')
    ;;
esac

case "$LOCAL"
in
    *)
    #L=$(echo "C:/Users/James/AppData/Local/Packages/CanonicalGroupLimited.UbuntuonWindows_79rhkp1fndgsc/LocalState/rootfs${LOCAL}" | sed 's,/,\\\\,g')
    L=$(echo `git rev-parse --show-toplevel`/"$LOCAL" | sed 's,/d/,D:/,g' | sed 's,/,\\\\,g')
    ;;
esac

case "$REMOTE"
in
    *)
    R=$(echo `git rev-parse --show-toplevel`/"$REMOTE" | sed 's,/d/,D:/,g' | sed 's,/,\\\\,g')
    ;;
esac

case "$MERGED"
in
    *)
    M=$(echo `git rev-parse --show-toplevel`/"$MERGED" | sed 's,/d/,D:/,g' | sed 's,/,\\\\,g')
    ;;
esac

echo "Git mergetool args:"
echo "$B"
echo "$L"
echo "$R"
echo "$M"

#p4merge.exe "$B" "$L" "$R" "$M"
"/mnt/c/Program Files/Perforce/p4merge.exe" "$B" "$L" "$R" "$M"
