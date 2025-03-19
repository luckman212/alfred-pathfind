#!/bin/zsh --no-rcs

if (( DEBUG == 1 )) ; then
	echo >&2 "🐞script \`${0:t}\` starting, args: $*"
	echo >&2 "🐞macOS: $(sw_vers | awk 'NR>1 { print $2 }' | paste -sd'-' -)"
fi

(( DEBUG == 1 )) && set -x

export dest_dir=/usr/local/bin
export this_dir=${0:h}
export this_script=${0:t}
PROMPT_PREFIX="$alfred_workflow_name is trying to"

if (( DEBUG == 1 )) ; then
	cat <<-EOF >&2
	🐞VAR: \`this_dir\`=$this_dir
	🐞VAR: \`this_script\`=$this_script
	EOF
fi

case $1 in
	create_symlink)
		ln -sf "$this_dir/pathfind.sh" $dest_dir/pathfind
		exit
		;;
	create_usrlocalbin)
		mkdir -p /usr/local/bin
		chown $USER:staff /usr/local/bin
		chmod 0755 /usr/local/bin
		exit
		;;
esac

if [[ ! -d $dest_dir ]]; then
	osascript <<-EOS
	do shell script "'$this_dir/$this_script' create_usrlocalbin" with administrator privileges with prompt "$PROMPT_PREFIX create the $dest_dir dir"
	EOS
	if [[ ! -d $dest_dir ]]; then
		echo >&2 "🐞failed to create $dest_dir"
		exit 1
	fi
fi

if ! ln -sf "$this_dir/pathfind.sh" $dest_dir/pathfind 2>/dev/null; then
	osascript <<-EOS
	do shell script "'$this_dir/$this_script' create_symlink" with administrator privileges with prompt "$PROMPT_PREFIX create a symlink at $dest_dir/pathfind"
	EOS
fi

if [[ -L $dest_dir/pathfind ]] && [[ -x $dest_dir/pathfind ]]; then
	cli_result=1
else
	cli_result=0
fi

if (( DEBUG == 1 )); then
	for i in /usr/local/{,bin,bin/pathfind}; do
		echo >&2 "🐞VAR: \`i\`=$i"
		file >&2 --brief --no-dereference --preserve-date $i
		ls >&2 -ledFOG@ "${i%/}"
	done
fi

cat <<EOJ
{
  "alfredworkflow": {
    "variables": {
      "cli_result": $cli_result
    }
  }
}
EOJ
