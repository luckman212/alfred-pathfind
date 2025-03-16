#!/bin/zsh --no-rcs

(( DEBUG == 1 )) && set -x

export dest_dir=/usr/local/bin
export this_dir=${0:h}
export this_script=${0:t}
PROMPT="$alfred_workflow_name is trying to install its commandline tool at $dest_dir"

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
	do shell script "sh $this_script create_usrlocalbin" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if ! ln -sf "$this_dir/pathfind.sh" $dest_dir/pathfind 2>/dev/null; then
	osascript <<-EOS
	do shell script "sh $this_script create_symlink" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if [[ -L $dest_dir/pathfind ]] && [[ -x $dest_dir/pathfind ]]; then
	cli_result=1
else
	cli_result=0
fi

if (( DEBUG == 1 )); then
	for i in /usr/local/{,bin,bin/pathfind}; do
		echo >&2 "🐞i: $i"
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
