{
  description = "Patched version of Caddy";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      # # A Nixpkgs overlay.
      # overlay = final: prev: {
      #   go = final.go_1_20;
      #   buildGoModule = final.buildGo117Module;
      # };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {

          caddy = pkgs.buildGoModule {
            pname = "caddy";
            inherit version;
            src = ./caddy-src;
            runVend = true;
            vendorHash = "sha256-GR+W9zHiscnARaP962oPUpiIrmU4Z7h47KzOjm0YNKk=";
            # vendorHash = pkgs.lib.fakeSha256;

            meta = {
              mainProgram = "caddy";
            };
          };

          default = self.packages.${system}.caddy;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go ];
          };
        }
      );

    };
}
