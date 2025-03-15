#!/bin/zsh --no-rcs

dest_dir=/usr/local/bin
PROMPT="$alfred_workflow_name is trying to install its commandline tool at $dest_dir"

if [[ ! -d $dest_dir ]]; then
	osascript <<-EOS
	do shell script "sh link.sh $USER" with administrator privileges with prompt "$PROMPT"
	EOS
fi

if ln -sf $PWD/pathfind.sh $dest_dir/pathfind ; then cli_result=1; else
	osascript <<-EOS
	do shell script "'ln -sf $PWD/pathfind.sh $dest_dir/pathfind'" with administrator privileges with prompt "$PROMPT"
	EOS
	(( $? != 0 )) && cli_result=0
fi

cat <<EOJ
{
  "alfredworkflow": {
    "variables": {
      "cli_result": ${cli_result:-2}
    }
  }
}
EOJ
