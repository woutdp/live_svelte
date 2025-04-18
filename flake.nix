{
  description = "A flake for building development environment of Phoenix project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs =
            [
              erlang_27
              beam.packages.erlang_26.elixir_1_18
              nodejs_22
              gh
            ]
            ++ lib.optionals stdenv.isLinux [
              # For ExUnit Notifier on Linux.
              libnotify

              # For file_system on Linux.
              inotify-tools
            ]
            ++ lib.optionals stdenv.isDarwin ([
              # For ExUnit Notifier on macOS.
              terminal-notifier

              # For file_system on macOS.
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.CoreServices
            ]);

          shellHook = ''
            # allows mix to work on the local directory
            mkdir -p .nix-mix
            mkdir -p .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export ERL_LIBS=$HEX_HOME/lib/erlang/lib

            # concats PATH
            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$MIX_HOME/escripts:$PATH
            export PATH=$HEX_HOME/bin:$PATH

            # enables history for IEx
            export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.erlang-history\"'"
          '';
        };
      }
    );
}
