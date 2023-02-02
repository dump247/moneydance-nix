{
  description = "Moneydance - Personal Finance Manager";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Version and sha256 of the Moneydance linux tarball
      version = "2022.6_4097";
      sha256 = "376d1e806f917e3730756b96428ce606e8b39847e24b082898a3ad1a96dfbf51";
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
