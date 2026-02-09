#!/usr/bin/env nu

# Import modrinth and curseforge mods from a list of project urls
def main [
  modlist: path, # The modlist file to read
  --dry-run(-d)  # Do a dry run where packwiz cli wont actually be called (useful for debuging)
]: nothing -> nothing {
  if not ($modlist | path exists) {
    print $'file "($modlist)" not found'
    exit 1
  }

	if not ("./pack.toml" | path exists) and not $dry_run {
		print "No pack.toml found"
		exit 1
	}

	let list: table<provider: string, id: string> = "provider,id\n" + (open $modlist
    | str replace --all --regex 'http(s)?:\/\/(?:www\.)?modrinth.com\/[^/]+\/(?<id>\S+)' 'modrinth,$id'
    | str replace --all --regex 'http(s)?:\/\/(?:www\.)?curseforge.com\/[^/]+\/(?<id>\S+)' 'curseforge,$id'
    | str replace --all --regex 'http(s)?:\/\/.*' '')
    | from csv

  for record in $list {
    print ($"> Provider: ($record.provider) " | fill -a right -c "=" -w 4)
    print ($"> Project ID: ($record.id) " | fill -a right -c "=" -w 4)
    match $record.provider {
      "modrinth" => (if $dry_run { print "add modrinth project" } else { ^packwiz mr add -y $record.id })
      "curseforge" => (if $dry_run { print "add curseforge project" } else { ^packwiz cf add -y $record.id })
      _ => (null)
    }
    print ""
  }

  print ($"> Modlist ($modlist) imported! " | fill -a right -c "=" -w 4)
}
