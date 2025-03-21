#!/bin/zsh --no-rcs

if (( DEBUG == 1 )) ; then
	echo >&2 "🐞script \`${0:t}\` starting, args: $*"
	echo >&2 "🐞macOS: $(sw_vers | awk 'NR>1 { print $2 }' | paste -sd'-' -)"
fi

SCRIPT_DIR="${0:A:h}"

_getAlfredWorkflowCfg() {
	WF_VARS=( ALLOW_XDEV MAX_DEPTH PATHFIND_PATHS PATHFIND_EXCLUDE_PATHS )
	JSON=$(plutil -convert json -o - -- "${SCRIPT_DIR}/info.plist" 2>/dev/null)
	[[ -n $JSON ]] || return 1
	for v in ${WF_VARS[@]}; do
		unset VALUE
		if ! VALUE=$(plutil -extract $v raw "${SCRIPT_DIR}/prefs.plist" 2>/dev/null); then
			VALUE=$(jq --raw-output --arg v "$v" <<< "$JSON" '
				.userconfigurationconfig | map(select(.variable==$v))[0] |
				.config |
				if .defaultvalue then
					.defaultvalue
				elif .default then
					.default
				else "" end')
		fi
		typeset -g "$v"=$VALUE
	done
}

case $1 in
	-h|--help|'') echo "Usage: ${0##*/} <word1> [word2...]"; exit;;
esac

# if running from an external shell, populate environment from WF config
[[ -z $alfred_workflow_uid ]] && _getAlfredWorkflowCfg

FD_ARGS=()
MD_QUERY=()
for a in "$@"; do
	if [[ $a == "in:"* ]]; then
		[[ ${a#in:} != "" ]] && MD_QUERY+=( 'kMDItemTextContent == "'${a#in:}'"c' '&&' )
	else
		SEARCH_KEYWORDS+=( "$a" )
	fi
done
MD_QUERY[-1]=() # remove trailing '&&'

case $ALLOW_XDEV in
	1) FD_ARGS+=( --follow );;
	0|*) FD_ARGS+=( --one-file-system --no-follow );; #if unset, use default (running from shell?)
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

_filterWithGawk() {
	nulbyte_delimited=$(printf '%s\0' "${SEARCH_KEYWORDS[@]}")
	gawk -v kw="$nulbyte_delimited" '
	BEGIN {
		IGNORECASE = 1;
		n = split(kw, words, "\0");
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
}

# ref: mdimport -X
_mdfind() {
	MD_ARGS=()
	for p in "${PATHFIND_PATHS_ARR[@]}"; do
		MD_ARGS+=( -onlyin ${~p} )
	done
	if (( DEBUG == 1 )); then
		echo >&2 "🐞executing mdfind"
		set -x
	fi
	mdfind 2>/dev/null "${MD_ARGS[@]}" "${MD_QUERY[@]}"
}

_multiple_args() {
	#hyperfine benchmark shows no improvement with LC_ALL=C, removed
	if (( DEBUG == 1 )); then
		echo >&2 "🐞multiple search terms (fd + gawk)"
		set -x
	fi
	fd 2>/dev/null \
		--color never \
		--absolute-path \
		"${FD_ARGS[@]}" |
	_filterWithGawk
}

# if we only have 1 search term, perform the matching with fd directly to speed execution
_single_arg() {
	FD_ARGS+=( --ignore-case )
	if (( DEBUG == 1 )); then
		echo >&2 "🐞single search term (handle exclusively with fd)"
		set -x
	fi
	fd 2>/dev/null \
		--color never \
		--absolute-path \
		"${FD_ARGS[@]}" -- "${SEARCH_KEYWORDS[1]}"
}

if [[ ${#MD_QUERY} -gt 0 ]]; then
	_mdfind | _filterWithGawk
else
	case ${#SEARCH_KEYWORDS} in
		0) echo >&2 "enter at least 1 search term"; exit 1;;
		1) _single_arg "${SEARCH_KEYWORDS[1]}";;
		*) _multiple_args "${SEARCH_KEYWORDS[@]}";;
	esac
fi
