{
  description = "Moneydance - Personal Finance Manager";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.05";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Version and sha256 of the Moneydance linux tarball
      version = "2022.5_4091";
      sha256 = "6bc9d9c4ad3b3a5368d79f8374991e6af75bb4038721c6c2f17506b185e6d560";
      moneydanceUrl = "https://infinitekind.com/stabledl/${version}/moneydance-linux.tar.gz";

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });

    in

    {

      # A Nixpkgs overlay.
      overlays.default = final: prev: {

        moneydance = with final; stdenv.mkDerivation rec {
          name = "moneydance-${version}";

          src = fetchurl {
            url = moneydanceUrl;
            inherit sha256;
          };

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

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) moneydance;
          default = nixpkgsFor.${system}.moneydance;
        });
    };
}
