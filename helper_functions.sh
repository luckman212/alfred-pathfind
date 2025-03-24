# shellcheck disable=all

_inAlfred() { [[ -n $alfred_workflow_uid ]]; }

_dbg() {
	(( DEBUG == 1 )) || return 0
	echo >&2 "🐞$1"
}

_argparse() {
	local query=$1
	local chars=("${(s::)query}")
	local chunk='' in_quote=0
	typeset -g args=()
	_dbg "argparse: original passed-in arg=[$query]"
	for char in "${chars[@]}"; do
		case $char in
			'"')
				if (( in_quote )); then
					in_quote=0
					args+=("$chunk")
					chunk=''
				else
					in_quote=1
				fi
				;;
			' ')
				if (( in_quote )); then
					chunk+=' '
				elif [[ -n $chunk ]]; then
					args+=("$chunk")
					chunk=''
				fi
				;;
			'/') # this is a reserved char in filenames, we also use it as the gawk delimiter
				if [[ -n $chunk ]]; then
					args+=("$chunk")
					chunk=''
				fi
				;;
			*)
				chunk+="$char"
				;;
		esac
	done
	[[ -n $chunk ]] && args+=("$chunk")
	if (( DEBUG == 1 )); then
		argcount=$#args
		_dbg "argparse: split as $argcount args"
		for (( c=1; c<=argcount; c++ )); do
			_dbg "arg $c = [${args[$c]}]"
		done
	fi
}
