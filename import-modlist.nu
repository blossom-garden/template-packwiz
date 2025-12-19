#!/usr/bin/env nu

def main [modlist: path] {
	if not ($modlist | path exists) {
		print $'file "($modlist)" not found'
		exit 1
	}

	if not ("./pack.toml" | path exists) {
		print "No pack.toml found"
		exit 1
	}

	let list = open $modlist | str replace --all --regex 'https://modrinth.com/(.*)/(?<id>.*)' '$id' | lines | where ($it =~ '\S{8}' and $it !~ 'http(s)?://.*')

	$list | each { |id|
		print ("> Project ID: ($id)" | fill -a right -c "=" -w 4)
		^packwiz mr add -y $id
		print ""

		null
	}

	null
}
