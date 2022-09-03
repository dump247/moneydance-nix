{
  description = "Moneydance - Personal Finance Manager";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let
      version = "2022.5_4091";
      versionUrl = "https://infinitekind.com/stabledl/${version}";

      linux = {
        sha256 = "6bc9d9c4ad3b3a5368d79f8374991e6af75bb4038721c6c2f17506b185e6d560";
        url = "${versionUrl}/moneydance-linux.tar.gz";
      };
    in
    {
      packages.x86_64-linux.default = with nixpkgs; stdenv.mkDerivation rec {
        name = "moneydance-${version}";

        src = fetchurl {
          inherit (linux) sha256 url;
        };

        buildCommand =
          let
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
          in
          ''
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
    };
}
