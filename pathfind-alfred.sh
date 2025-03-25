#!/bin/zsh --no-rcs

zmodload zsh/datetime

. ./helper_functions.sh

if (( DEBUG == 1 )) ; then
	echo >&2 "🐞$alfred_workflow_name v${alfred_workflow_version}"
	echo >&2 "🐞script \`${0:t}\` starting, args: $*"
	echo >&2 "🐞macOS: $(sw_vers | awk 'NR>1 { print $2 }' | paste -sd'-' -)"
fi

# prereq check
[[ -n $DEPS ]] || exit 1
DEPS_ARR=("${(@z)DEPS}")
if ! hash ${DEPS_ARR[@]} &>/dev/null; then
	osascript <<-EOS 2>/dev/null
	tell application id "com.runningwithcrayons.Alfred"
		run trigger "deps" in workflow "$alfred_workflow_bundleid"
	end tell
	EOS
	exit 1
fi

ICON_JSON='{ "path": "./icon.png" }'
if [[ -n $SEARCH_DESCRIPTION ]]; then
	export alfred_workflow_description=$SEARCH_DESCRIPTION
fi
if [[ -z $1 ]]; then
	if [[ -n $ICON_OVERRIDE ]]; then
		ICON_JSON="{ \"path\": \"$ICON_OVERRIDE\" }"
	fi
	cat <<-EOJ
	{ "items": [{
		"title": "${WF_TITLE_OVERRIDE:-$alfred_workflow_name}",
		"subtitle": "${alfred_workflow_description}",
		"icon": $ICON_JSON,
		"valid": false,
		"mods": {
			"cmd": { "valid": false },
			"alt": { "subtitle": "", "valid": false },
			"ctrl": { "valid": false }
		}
	}]}
	EOJ
	exit
fi

# ensure we have at least 1 path
if [[ -z $PATHFIND_PATHS ]]; then
	export PATHFIND_PATHS=$PWD
fi

# path prefix hiders
HIDDEN_PREFIXES_ARR=("${(@f)HIDDEN_PREFIXES}")

#sourced from helper_functions.sh
_argparse $1

# item_depth = the number of directories ABOVE the item
# if pdd == 0 then show full path in subtitle
export START_TIME=$EPOCHREALTIME
./pathfind.sh "${args[@]}" |
jq \
	--null-input \
	--raw-input \
	--argjson st "$START_TIME" '
	($ENV.PATH_DISPLAY_DEPTH // 0 | tonumber) as $pdd |
	($ENV.SLOW_AFTER // 0 | tonumber) as $slow |
	($ENV.DEBUG // 0 | tonumber == 1) as $dbg |

	($ARGS.positional | map(
		sub("^\\s+";"") | sub("\\s+$";"") | sub("/$";"") |
		select(length>0))) as $hide_pfx |

	if $dbg then
		debug("🐞debugging enabled") |
		debug("🐞PATH_DISPLAY_DEPTH=\($pdd)") |
		debug("🐞MAX_DEPTH=\($ENV.MAX_DEPTH)") |
		debug("🐞ALLOW_XDEV=\($ENV.ALLOW_XDEV)") |
		debug("🐞hide_pfx:", $hide_pfx)
	else . end |

	[inputs] | map(
	. as $raw |
	(sub("/$";"") | sub("^\($ENV.HOME)/";"~/")) as $fqpn |

	$fqpn | split("/")     as $fqpn_els |
	$fqpn_els[-1]          as $item_name |
	$fqpn_els[:-1]         as $parent_dirs |
	$parent_dirs | length  as $item_depth |

	(if
		($pdd == 0 or $pdd >= $item_depth) then
			$parent_dirs
		else
			[ "…" ] + $parent_dirs[-$pdd:]
		end | join("/")
	) as $sub |

	(reduce $hide_pfx[] as $pfx ($sub;
		if startswith($pfx) then ltrimstr($pfx) else . end
	)) as $sub |

	{
		title: $item_name,
		subtitle: $sub,
		arg: $raw,
		icon: { type: "fileicon", path: $fqpn },
		quicklookurl: $fqpn,
		mods: {
			cmd: {
				variables: { action: "reveal" },
				subtitle: "↩ reveal in Finder"
			},
			alt: { subtitle: "", valid: false },
			"cmd+alt": {
				variables: { action: "reveal_bg" },
				subtitle: "↩ reveal in Finder (without closing Alfred)"
			},
			ctrl: { valid: false }
		}
	}) as $results |

	(if ($slow>0 and (now-$st)>$slow) or $dbg then [{
		title: "Script execution time: \((now-$st)*1000|floor) ms",
		icon: { path: "turtle.png" },
		subtitle: "If slow, try reducing the search scope or depth",
		valid: false
	}]
	else [] end) as $time |
	{ items: (
		$time +
		if ($results|length)>0 then $results
		else [{
			title: "Nothing found!",
			subtitle: "Try some different search terms",
			icon: { path: "error.png" },
			valid: false,
			mods: {
				cmd: { valid: false },
				alt: { subtitle: "", valid: false },
				ctrl: { valid: false }
			}
		}] end)
	}' --args "${HIDDEN_PREFIXES_ARR[@]}"

if (( DEBUG == 1 )); then
	ELAPSED=$(( (EPOCHREALTIME-START_TIME) * 1000))
	printf >&2 '🐞%s completed in %.0f ms\n' "${0:t}" $ELAPSED
fi
