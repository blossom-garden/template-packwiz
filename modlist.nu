#!/usr/bin/env nu

# Import modrinth and curseforge mods from a list of project urls
export def "import" [
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
      "modrinth" => (add mr $record.id $dry_run)
      "curseforge" => (add cf $record.id $dry_run)
      _ => (null)
    }
  }

  print $"\n\e[38;2;38;35;58m\e[48;2;38;35;58;38;2;196;167;231m Modlist ($modlist) imported! \e[0m\e[38;2;38;35;58m\e[0m\n"
}

def "add mr" [id: string, dry: bool = false]: nothing -> nothing {
  if $dry {
    print $"add modrinth project ($id)"
  } else {
    do -i { ^packwiz mr add -y --project-id $id }
  }
}
def "add cf" [id: int, dry: bool = false]: nothing -> nothing {
  if $dry {
    print $"add curseforge project ($id)"
  } else {
    do -i { ^packwiz cf add -y --addon-id $id }
  }
}

# Export all the mods into a modlist in markdown format
export def "export" []: nothing -> string {
  let list: list<record<name: string, id: any, provider: string>> = ls **/*.pw.toml
  | each {|it| open $it.name}
  | where update? != null
  | each {|it| {
    name: $it.name,
    id: (if $it.update.modrinth? != null {$it.update.modrinth.mod-id} else {$it.update.curseforge.project-id}),
    provider: (if $it.update.modrinth? != null {'modrinth'} else {'curseforge'})
  }}
  let markdown: string = $list | each {|it|
    let url: string = match $it.provider {
      "modrinth" => $"https://modrinth.com/project/($it.id)",
      "curseforge" => $"https://curseforge.com/projects/($it.id)"
    }
    $"- [($it.name)]\(($url)\)"
  } | str join "\n"

  $markdown
}

# Returns the most recently added files
export def "changelog" []: nothing -> string {
  let list: list<record<name: string, id: any, provider: string>> = ls -l **/*.pw.toml
  | group-by created | transpose date count
  | first 1 | get count | get 0
  | each {|it| open $it.name}
  | where update? != null
  | each {|it| {
    name: ($it.name | str trim | str replace "[" "\\[" | str replace "]" "\\]"),
    id: (if $it.update.modrinth? != null {$it.update.modrinth.mod-id} else {$it.update.curseforge.project-id}),
    provider: (if $it.update.modrinth? != null {'modrinth'} else {'curseforge'})
  }}

  let markdown: string = $list | each {|it|
    let url: string = match $it.provider {
      "modrinth" => $"https://modrinth.com/project/($it.id)",
      "curseforge" => $"https://curseforge.com/projects/($it.id)"
    }
    let name = ($it.name | str trim | str replace "[" "\\[" | str replace "]" "\\]")
    $"- [($name)]\(($url)\)"
  } | str join "\n"

  $markdown
}
