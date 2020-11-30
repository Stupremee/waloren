{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    pkgsmoz = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, naersk, pkgsmoz }:
    utils.lib.eachDefaultSystem (system:
      let
        pname = "waloren";

        mozilla = pkgs.callPackage (pkgsmoz + "/package-set.nix") { };
        rust = (mozilla.rustChannelOf {
          rustToolchain = ./rust-toolchain;
          sha256 = "sha256-P4FTKRe0nM1FRDV0Q+QY2WcC8M9IR7aPMMLWDfv+rEk=";
        }).rust;

        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = naersk.lib."${system}".override {
          cargo = rust;
          rustc = rust;
        };
      in rec {
        # `nix build`
        packages = {
          "${pname}" = naersk-lib.buildPackage {
            inherit pname;
            root = ./.;
            release = true;
          };

          test = naersk-lib.buildPackage {
            inherit pname;
            root = ./.;

            RUST_BACKTRACE = 1;

            release = false;
            doCheck = true;
          };
        };
        defaultPackage = packages."${pname}";

        # `nix run`
        apps."${pname}" = utils.lib.mkApp { drv = packages."${pname}"; };
        defaultApp = apps."${pname}";

        # `nix develop`
        devShell = pkgs.mkShell { nativeBuildInputs = [ rust ]; };
      });
}
