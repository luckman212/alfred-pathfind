#!/bin/zsh --no-rcs

case $1 in
	-h|--help|'') echo "Usage: ${0##*/} <word1> [word2...]"; exit;;
esac

FD_ARGS=()

case $ALLOW_XDEV in
	0) FD_ARGS+=( --one-file-system --no-follow );;
	1) FD_ARGS+=( --follow );;
	*) exit 1;; # ???
esac

#files, dirs or both
case $TYPE_OVERRIDE in
	file) FD_ARGS+=( --type file );;
	directory) FD_ARGS+=( --type directory );;
	'') FD_ARGS+=( --type file --type directory );;
	*) exit 1;; # ???
esac

#depth
if (( MAX_DEPTH > 0 )); then
	FD_ARGS+=( --max-depth $MAX_DEPTH )
fi

#paths and exclusions
if [[ -z $PATHFIND_PATHS ]]; then
	FD_ARGS+=( --search-path "$PWD" )
else
	PATHFIND_PATHS_ARR=("${(@f)PATHFIND_PATHS}")
	for p in "${PATHFIND_PATHS_ARR[@]}"; do
		pe=$(eval echo "$p")
		FD_ARGS+=( --search-path "$pe" )
	done
fi
if [[ -n $PATHFIND_EXCLUDE_PATHS ]]; then
	PATHFIND_EXCLUDE_PATHS_ARR=("${(@f)PATHFIND_EXCLUDE_PATHS}")
	for p in "${PATHFIND_EXCLUDE_PATHS_ARR[@]}"; do
		pe=$(eval echo "$p")
		FD_ARGS+=( --exclude "$pe" )
	done
fi

#hyperfine benchmark shows no improvement
#LC_ALL=C
fd 2>/dev/null \
	--color never \
	--absolute-path \
	"${FD_ARGS[@]}" |
gawk -v SEARCH_KEYWORDS="$*" '
BEGIN {
	IGNORECASE = 1;
	n = split(SEARCH_KEYWORDS, words, " ");
	for (i = 1; i <= n; i++) {
		searchterms[toupper(words[i])] = 1;
	}
}
{
	line = toupper($0);
	for (word in searchterms) {
		if (line !~ word) { next; }
	}
	print $0;
}'
