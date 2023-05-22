{
  description = "Moneydance - Personal Finance Manager";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }:
  let
    # Version and sha256 of the Moneydance linux tarball
    version = "2023.1_5006";
    sha256 = "e8fe0d3941b35ba9230bcfc49127d6940230da03b16392d11ecc14a1c8ffc521";
    url = "https://infinitekind.com/stabledl/${version}/moneydance-linux.tar.gz";

    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    package = with pkgs; stdenv.mkDerivation rec {
      name = "moneydance-${version}";

      src = fetchurl { inherit sha256 url; };

      buildCommand = let
        jreLibPath = lib.makeLibraryPath [
          zlib
          xorg.libXext
          xorg.libXtst
          xorg.libX11
          xorg.libXrender
          xorg.libXi
          freetype
          fontconfig
        ];
      in ''
      # Unpack the tarball, removing the leading "moneydance/" directory.
      mkdir -p "$out"
      tar xfvz "$src" --strip-components=1 -C "$out"

      # Patch the Java interpreter load library paths
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "$out/jre/lib:${jreLibPath}" \
        "$out"/jre/bin/*

      patchelf \
        --set-rpath "$out/jre/lib:${jreLibPath}" \
        "$out"/jre/lib/*.so
      '';
    };
  in
  {
    checks.${system}.default = pkgs.runCommand "moneydance-${version}-check" {} ''
      set -e

      # Check if java can run (no library discovery failures)
      ${package}/jre/bin/java --version

      # TODO check that java can load varous X libs?

      # Create the out dir so nix knows the derivation completed successfully
      mkdir $out
      '';

    packages.${system}.default = package;
  };
}
