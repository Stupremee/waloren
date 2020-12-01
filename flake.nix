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
        manifest = builtins.fromTOML (builtins.readFile ./Cargo.toml);
        version = manifest.package.version;
        pname = manifest.package.name;

        mozilla = pkgs.callPackage (pkgsmoz + "/package-set.nix") { };
        rust = (mozilla.rustChannelOf {
          rustToolchain = ./rust-toolchain;
          sha256 = "sha256-P4FTKRe0nM1FRDV0Q+QY2WcC8M9IR7aPMMLWDfv+rEk=";
        }).rust.override { targets = [ "wasm32-unknown-unknown" ]; };

        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = naersk.lib."${system}".override {
          cargo = rust;
          rustc = rust;
        };

        raw-lib = naersk-lib.buildPackage {
          inherit version;
          pname = "${pname}-raw";
          root = ./.;

          cargoBuildOptions = old: old ++ [ "--target wasm32-unknown-unknown" ];
          copyBins = false;
          copyLibs = true;
          release = true;
        };
      in rec {
        # `nix build`
        packages = {
          "${pname}" = pkgs.stdenv.mkDerivation {
            inherit pname version;
            src = raw-lib;
            nativeBuildInputs = [ pkgs.wasm-bindgen-cli pkgs.makeWrapper ];
            buildPhase = ''
              mkdir -p $out/www
              for module in $src/lib/*; do
                ${pkgs.wasm-bindgen-cli}/bin/wasm-bindgen --target web --no-typescript --out-dir $out/www $module
              done
            '';

            installPhase = ''
              mkdir $out/bin
              cp -a ${./index.html} $out/www/index.html
              ln -s ${pkgs.miniserve}/bin/miniserve $out/bin/waloren
              wrapProgram $out/bin/waloren --add-flags "$out/www"
            '';
          };
        };
        defaultPackage = packages."${pname}";

        # `nix run`
        apps."${pname}" = utils.lib.mkApp { drv = packages."${pname}"; };
        defaultApp = apps."${pname}";

        # `nix develop`
        devShell =
          pkgs.mkShell { nativeBuildInputs = [ rust pkgs.wasm-bindgen-cli ]; };
      });
}
