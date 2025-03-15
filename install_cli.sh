#!/bin/zsh --no-rcs

dest_dir=/usr/local/bin
PROMPT="$alfred_workflow_name is trying to install its commandline tool at $dest_dir"

if [[ ! -d $dest_dir ]]; then
	osascript <<-EOS
	do shell script "sh link.sh $USER" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if ln -sf $PWD/pathfind.sh $dest_dir/pathfind ; then rc=0; else
	osascript <<-EOS
	do shell script "'ln -sf $PWD/pathfind.sh $dest_dir/pathfind'" with administrator privileges with prompt "$PROMPT"
	EOS
	(( $rc != 0 )) && rc=1
	fi

cat <<EOJ
{
  "alfredworkflow": {
    "variables": {
      "cli_result": ${rc:-2}
    }
  }
}
EOJ
