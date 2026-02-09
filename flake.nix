{
  description = "Packwiz minecraft mopack enviroment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { nixpkgs, systems, ... }:
    let
      forEachSystem =
        fn:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          fn (
            import nixpkgs {
              inherit system;
            }
          )
        );
    in
    {
      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.packwiz ];
        };
      });
    };
}
