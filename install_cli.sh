#!/bin/zsh --no-rcs

export dest_dir=/usr/local/bin
PROMPT="$alfred_workflow_name is trying to install its commandline tool at $dest_dir"

if [[ ! -d $dest_dir ]]; then
	osascript <<-EOS
	do shell script "sh link.sh create_usrlocalbin" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if ! ln -sf $PWD/pathfind.sh $dest_dir/pathfind 2>/dev/null; then
	osascript <<-EOS
	do shell script "sh link.sh create_symlink" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if [[ -L $dest_dir/pathfind ]] && [[ -x $dest_dir/pathfind ]]; then
	cli_result=1
else
	cli_result=0
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
