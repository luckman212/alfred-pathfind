#!/bin/zsh --no-rcs

source "${0:A:h}/helper_functions.sh"

if _isTrue DEBUG ; then
	echo >&2 "🐞script \`${0:t}\` starting"
	echo >&2 "🐞macOS: $(sw_vers | awk 'NR>1 { print $2 }' | paste -sd'-' -)"
fi

[[ -n $DEPS ]] || exit 1
DEPS_ARR=("${(@z)DEPS}")

if hash &>/dev/null ${DEPS_ARR[@]} ; then
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
	nohup -- brew install ${DEPS_ARR[@]} >/dev/null 2>&1 &
	SPID=$!
fi

cat <<-EOJ
	{ "rerun": 0.75,
		"variables": { "SPID": "$SPID" },
		"items": [{
			"title": "Installing required components ($DEPS)...",
			"subtitle": "Please wait, workflow will auto-refresh when ready",
			"icon": { "path": "./brew.png" },
			"valid": false,
		}]
	}
EOJ
