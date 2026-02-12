#!/usr/bin/env nu

# Verify all dependency mods for the datapack
def main [outfile?: path = './dependencies.txt']: nothing -> nothing {
	let files: table<name: string, slug: string, pin: bool> = ls **/*.pw.toml | where name =~ '(resourcepacks|shaders|mods)' | each { |file|
		open $file.name | insert slug { $file.name | str replace -r '(resourcepacks|mods|shaders)/' '' | str replace '.pw.toml' '' }
	} | select name slug pin?

  let dependencies = $files | each {|file|
    $file.slug + "(embedded)"
  } | str join "\n"

  $dependencies | save -f $outfile
}
