let
  year = "2022";
  release = "4";
  patch = "4087";
  sha256 = "9f4db2427abe311361eb2a5b298713c0805263e56e277a99ac37b3cb5a79c4ab";
  pkgs = import <nixpkgs> {};
in with pkgs; stdenv.mkDerivation rec {
  name = "moneydance";
  src = fetchurl {
    url = "https://infinitekind.com/stabledl/${year}.${release}_${patch}/moneydance-linux.tar.gz";
    inherit sha256;
  };
  buildCommand = let
    # Libraries required by the bundled java runtime
    jreLibPath = lib.makeLibraryPath [
      zlib
      xorg.libXext
      xorg.libX11
      xorg.libXrender
      xorg.libXtst
      xorg.libXi
      freetype
      fontconfig
    ];
  in ''
    # Unpack tarball. Remove the leading "moneydance/" directory.
    mkdir -p $out
    tar xfvz $src --strip-components=1 -C $out

    # Patch the Java interpreter load library paths
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "$out/jre/lib:${jreLibPath}" \
      $out/jre/bin/*

    patchelf \
      --set-rpath "$out/jre/lib:${jreLibPath}" \
      $out/jre/lib/*.so
  '';
}
