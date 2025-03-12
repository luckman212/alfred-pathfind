#!/usr/bin/env osascript -l JavaScript

ObjC.import('Foundation');

const finder = Application("Finder");
let awjson = { items: [] };

function getArgs() {
	return ObjC.unwrap($.NSProcessInfo.processInfo.arguments).map(ObjC.unwrap);
}

function posixPath(finderWindow) {
	return $.NSURL.URLWithString(finderWindow.url()).fileSystemRepresentation;
}

function getEnv(var_name, def_val = "") {
	let v = ObjC.unwrap($.NSProcessInfo.processInfo.environment.objectForKey(var_name));
	return v === undefined ? def_val : v;
}

let argv = getArgs().slice(4);
console.log(argv);

try {
	let p = posixPath(finder.insertionLocation());
	let lastElement = p.split("/").pop();
	awjson.items.push({
		"title": `${getEnv('alfred_workflow_name')} in “${lastElement}”`,
		"subtitle": `Press ↩ to continue`,
		"arg": argv[0],
		"variables": {
			"PATHFIND_PATHS": p,
			"SEARCH_DESCRIPTION": `Searching in “${lastElement}”`,
			"ICON_OVERRIDE": "current.png"
		}
	});
} catch {
	console.log("error getting finderWindow");
}

JSON.stringify(awjson);
