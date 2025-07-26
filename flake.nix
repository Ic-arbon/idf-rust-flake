{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    esp32 = pkgs.dockerTools.pullImage {
      imageName = "espressif/idf-rust";
      imageDigest = "sha256:5155a0f2dafadaabb2b2fb6a4f1d3dcb9209d814d150427622fc07e5fbda08f2";
      sha256 = "hjkyIEMKda9SQ+6pC/z5LRhVmDMqVp518PHIsoLjPnk=";
      finalImageName = "espressif/idf-rust";
      finalImageTag = "all_latest";
    };
  in {
    packages.x86_64-linux.esp32 = pkgs.stdenv.mkDerivation {
      name = "esp32";
      src = esp32;
      unpackPhase = ''
        mkdir -p source
        tar -C source -xvf $src
      '';
      sourceRoot = "source";
      nativeBuildInputs = [
        pkgs.autoPatchelfHook
        pkgs.jq
      ];
      buildInputs = [
        pkgs.xz
        pkgs.zlib
        pkgs.libxml2
        pkgs.python3
        pkgs.libudev-zero
        pkgs.stdenv.cc.cc
      ];
      buildPhase = ''
        jq -r '.[0].Layers | @tsv' < manifest.json > layers
      '';
      installPhase = ''
        mkdir -p $out
        for i in $(< layers); do
          tar -C $out -xvf "$i" home/esp/.cargo home/esp/.rustup || true
        done
        mv -t $out $out/home/esp/{.cargo,.rustup}
        rmdir $out/home/esp
        rmdir $out/home
        export PATH=$out/.rustup/toolchains/esp/bin:$PATH
        export PATH=$out/.rustup/toolchains/esp/xtensa-esp-elf-esp-13.2.0_20230928/stensa-esp-elf/bin:$PATH
        export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"

        # [ -d $out/.cargo ] && [ -d $out/.rustup ]
      '';
    };
  };
}
