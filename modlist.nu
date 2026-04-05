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

  print $"\n(ansi '#26233a')(ansi {fg: '#c4a7e7', bg: '#26233a'}) Modlist ($modlist) imported! (ansi rst)(ansi '#26233a')(ansi rst)\n"
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
  | each {|it| $it | get-metadata}
  let markdown: string = $list | each {|it|
    let url: string = match $it.provider {
      "modrinth" => $"https://modrinth.com/project/($it.id)",
      "curseforge" => $"https://curseforge.com/projects/($it.id)"
    }
    $"- [($it.name)]\(($url)\)"
  } | str join "\n"

  $markdown
}

def get-metadata []: [
  record -> record<name: string, provider: string, id: string>
  record -> record<name: string, provider: string, id: int>
] {
    let provider: string = ($in | get update | columns | first)
    let id = match $provider {
      "modrinth" => ($in | get update.modrinth.mod-id?),
      "curseforge" => ($in | get update.curseforge.project-id?),
      _ => "",
    }
    { name: $in.name, provider: $provider, id: $id }
}

def generate-link []: record<name: string, id: any, provider: string> -> string {
    let url: string = match $in.provider {
      "modrinth" => $"https://modrinth.com/project/($in.id)",
      "curseforge" => $"https://curseforge.com/projects/($in.id)",
      _ => ""
    }
    let name = ($in.name | str trim | str replace "[" "\\[" | str replace "]" "\\]")
    $"- [($name)]\(($url)\)"
}

def "get added" [diff: list<record<status: string, file: string>>]: nothing -> list<record<name: string, id: any, provider: string>> {
  $diff
  | where status == "A" | get file | each {|it| open $it}
  | where update? != null
  | each {|it| $it | get-metadata }
}

def "get removed" [diff: list<record<status: string, file: string>>]: nothing -> list<record<name: string, id: any, provider: string>> {
  $diff
  | where status == "D" | get file | each {|it|
    mut commit: string = git log --diff-filter=D --pretty="%h" -- $it
    if ($commit | is-empty) { $commit = "HEAD" }
    (git show ($commit):($it) | from toml)
  }
  | where update? != null
  | each {|it| $it | get-metadata }
}

# Returns the most recently added files
export def "changelog" []: nothing -> string {
  let diff: list<record<status: string, file: string>> = git diff --name-status --cached
  | str replace -r -a "\t" "»¦«"
  | lines | where $it =~ ".pw.toml"
  | split column "»¦«" status file

  let added: list<record<name: string, id: any, provider: string>> = get added $diff
  let removed: list<record<name: string, id: any, provider: string>> = get removed $diff

  let added_links: string = $added | each {|i| $i | generate-link } | str join "\n"
  let removed_links: string = $removed | each {|i| $i | generate-link } | str join "\n"

  let markdown: string = $"**Adicionado**\n\n($added_links)"
  if ($removed_links | is-not-empty) { return $"($markdown)\n\n**Removido**\n\n($removed_links)" }
  $markdown
}
