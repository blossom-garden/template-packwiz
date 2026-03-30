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
    print $record
    match $record.provider {
      "modrinth" => (add mr --dry-run=$dry_run $record.id)
      "curseforge" => (add cf --dry-run=$dry_run $record.id)
      _ => (null)
    }
  }

  print $"\e[38;2;38;35;58m\e[48;2;38;35;58;38;2;196;167;231m Modlist ($modlist) imported! \e[0m\e[38;2;38;35;58m\e[0m"
}

def "add mr" [id: string, --dry-run(-d)]: nothing -> nothing {
  if $dry_run {
    print $"add modrinth project ($id)"
  } else {
    do -i { ^packwiz mr add -y --project-id $id }
  }
}
def "add cf" [id: string, --dry-run(-d)]: nothing -> nothing {
  if $dry_run {
    print $"add curseforge project ($id)"
  } else {
    do -i { ^packwiz cf add -y --addon-id $id }
  }
}
