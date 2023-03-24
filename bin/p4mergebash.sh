#!/bin/sh

# =============
# The following config should be included in ~/.gitconfig
# =============
#
#[merge]
#        tool = p4mergebash
#[mergetool "p4merge"]
#        path = "/c/Program Files/Perforce/p4merge.exe"
#        cmd = "/c/Program Files/Perforce/p4merge.exe \"$BASE\" \"$LOCAL\" \"$REMOTE\" \"$MERGED\""
#[mergetool "p4mergebash"]
#        cmd = ~/.dotfiles/bin/p4mergebash.sh $BASE $LOCAL $REMOTE $MERGED
#        trustExitCode = true
#[diff]
#        tool = p4mergebash
#[difftool "p4mergebash"]
#        cmd = ~/.dotfiles/bin/p4mergebash.sh $BASE $LOCAL $REMOTE
#[difftool]
#        prompt = false

BASE=`echo $1 | sed 's,^\.,,g'`
LOCAL=`echo $2 | sed 's,^\.,,g'`
REMOTE=`echo $3 | sed 's,^\.,,g'`
#MERGED=`echo $4 | sed 's,^\.,,g'`
MERGED=`echo $4`

# Map the path supplied to p4merge
# This is so the Windows host (WSl2) can access the network share
map_p4_args() {
  FILE_PATH="$1"
  echo "${P4MERGE_PREPEND}${FILE_PATH}${P4MERGE_APPEND}"
}

case "$BASE"
in
    *)
    B=$(echo `git rev-parse --show-toplevel`/"$BASE" | sed 's,/d/,D:/,g' | sed 's,/,\\\\,g')
    ;;
esac

case "$LOCAL"
in
    *)
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

#echo "Git mergetool args:"
#echo $(map_p4_args "$B")
#echo $(map_p4_args "$L")
#echo $(map_p4_args "$R")
#echo $(map_p4_args "$M")

#p4merge.exe "$B" "$L" "$R" "$M"
"$P4MERGE_BINARY" $(map_p4_args "$B") $(map_p4_args "$L") $(map_p4_args "$R") $(map_p4_args "$M")
