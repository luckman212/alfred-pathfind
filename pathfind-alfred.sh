#!/bin/zsh --no-rcs

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
		"title": "${alfred_workflow_name:-<workflow_name>}",
		"subtitle": "${alfred_workflow_description:-<workflow_description>}",
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
mapfile -t HIDDEN_PREFIXES_ARR <<< "$HIDDEN_PREFIXES"

# item_depth = the number of directories ABOVE the item
# if pdd == 0 then show full path in subtitle
./pathfind.sh "$@" |
jq \
	--null-input \
	--raw-input '
	($ENV.PATH_DISPLAY_DEPTH // 0 | tonumber) as $pdd |
	if $ENV.DEBUG then debug("🐞PATH_DISPLAY_DEPTH=\($pdd) MAX_DEPTH=\($ENV.MAX_DEPTH)") else . end |

	($ARGS.positional | map(
		sub("^\\s+";"") | sub("\\s+$";"") | sub("/$";"") |
		select(length>0))) as $hide_pfx |

	debug("🐞pfx", $hide_pfx) |

	[inputs] | map(
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
		arg: $fqpn,
		icon: { type: "fileicon", path: $fqpn },
		quicklookurl: $fqpn,
		mods: {
			cmd: { action: "reveal", subtitle: "↩ reveal in Finder" },
			alt: { subtitle: "", valid: false },
			ctrl: { valid: false }
		}
	}) as $results |

	{ items: (
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
