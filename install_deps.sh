#!/usr/bin/env bash

if hash &>/dev/null fd gawk jq ; then
	osascript <<-EOS 2>/dev/null
	tell application id "com.runningwithcrayons.Alfred"
		run trigger "entrypoint" in workflow "$alfred_workflow_bundleid" with argument ""
	end tell
	EOS
	exit 0
fi

if ! hash &>/dev/null brew ; then
	cat <<-EOJ
	{ "items": [{
		"title": "Homebrew is not installed!",
		"subtitle": "↩ visit brew.sh for install instructions",
		"arg": "https://brew.sh/",
		"icon": { "path": "./brew.png" }
	}]}
	EOJ
	exit 0
fi

if [[ -z $SPID ]]; then
	#echo >&2 "🍺installing components"
	nohup -- brew install fd gawk jq >/dev/null 2>&1 &
	SPID=$!
	disown $SPID
fi

cat <<-EOJ
	{ "rerun": 0.75,
		"variables": { "SPID": "$SPID" },
		"items": [{
			"title": "Installing required components...",
			"subtitle": "Please wait, workflow will auto-refresh when ready",
			"icon": { "path": "./brew.png" },
			"valid": false,
		}]
	}
EOJ
