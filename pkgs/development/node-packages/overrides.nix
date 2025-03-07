# Do not use overrides in this file to add  `meta.mainProgram` to packages. Use `./main-programs.nix`
# instead.
{ pkgs, nodejs }:

let
  inherit (pkgs)
    stdenv
    lib
    callPackage
    fetchFromGitHub
    fetchurl
    fetchpatch
    nixosTests;

  since = version: lib.versionAtLeast nodejs.version version;
  before = version: lib.versionOlder nodejs.version version;
in

final: prev: {
  inherit nodejs;

  "@angular/cli" = prev."@angular/cli".override {
    prePatch = ''
      export NG_CLI_ANALYTICS=false
    '';
  };

  "@electron-forge/cli" = prev."@electron-forge/cli".override {
    buildInputs = [ final.node-gyp-build ];
  };

  "@forge/cli" = prev."@forge/cli".override {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs; [
      libsecret
      final.node-gyp-build
      final.node-pre-gyp
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.AppKit
      darwin.apple_sdk.frameworks.Security
    ];
  };

  "@medable/mdctl-cli" = prev."@medable/mdctl-cli".override (oldAttrs: {
    nativeBuildInputs = with pkgs; with darwin.apple_sdk.frameworks; [
      glib
      libsecret
      pkg-config
    ] ++ lib.optionals stdenv.isDarwin [
      AppKit
      Security
    ];
    buildInputs = [
      final.node-gyp-build
      final.node-pre-gyp
      nodejs
    ];

    meta = oldAttrs.meta // { broken = since "16"; };
  });
  mdctl-cli = final."@medable/mdctl-cli";

  autoprefixer = prev.autoprefixer.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/autoprefixer" \
        --prefix NODE_PATH : ${final.postcss}/lib/node_modules
    '';
    passthru.tests = {
      simple-execution = callPackage ./package-tests/autoprefixer.nix { inherit (final) autoprefixer; };
    };
  };

  aws-azure-login = prev.aws-azure-login.override (oldAttrs: {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    prePatch = ''
      export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    '';
    postInstall = ''
      wrapProgram $out/bin/aws-azure-login \
          --set PUPPETEER_EXECUTABLE_PATH ${pkgs.chromium}/bin/chromium
    '';
    meta = oldAttrs.meta // { platforms = lib.platforms.linux; };
  });

  balanceofsatoshis = prev.balanceofsatoshis.override {
    nativeBuildInputs = [ pkgs.installShellFiles ];
    postInstall = ''
      installShellCompletion --cmd bos\
        --bash <($out/bin/bos completion bash)\
        --zsh <($out/bin/bos completion zsh)\
        --fish <($out/bin/bos completion fish)
    '';
  };

  bitwarden-cli = prev."@bitwarden/cli".override {
    name = "bitwarden-cli";
    nativeBuildInputs = with pkgs; [
      pkg-config
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreText
    ];
    buildInputs = with pkgs; [
      pixman
      cairo
      pango
      giflib
    ];
  };

  bower2nix = prev.bower2nix.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      for prog in bower2nix fetch-bower; do
        wrapProgram "$out/bin/$prog" --prefix PATH : ${lib.makeBinPath [ pkgs.git pkgs.nix ]}
      done
    '';
  };

  carbon-now-cli = prev.carbon-now-cli.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    prePatch = ''
      export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    '';
    postInstall = ''
      wrapProgram $out/bin/carbon-now \
        --set PUPPETEER_EXECUTABLE_PATH ${pkgs.chromium.outPath}/bin/chromium
    '';
  };

  coc-imselect = prev.coc-imselect.override (oldAttrs: {
    meta = oldAttrs.meta // { broken = since "10"; };
  });

  dat = prev.dat.override (oldAttrs: {
    buildInputs = [ final.node-gyp-build pkgs.libtool pkgs.autoconf pkgs.automake ];
    meta = oldAttrs.meta // { broken = since "12"; };
  });

  castnow = prev.castnow.override {
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram "$out/bin/castnow" \
          --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ffmpeg ]}
    '';
  };

  eask = prev."@emacs-eask/cli".override {
    name = "eask";
  };

  expo-cli = prev."expo-cli".override (oldAttrs: {
    # The traveling-fastlane-darwin optional dependency aborts build on Linux.
    dependencies = builtins.filter (d: d.packageName != "@expo/traveling-fastlane-${if stdenv.isLinux then "darwin" else "linux"}") oldAttrs.dependencies;
  });

  fast-cli = prev.fast-cli.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    prePatch = ''
      export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    '';
    postInstall = ''
      wrapProgram $out/bin/fast \
        --set PUPPETEER_EXECUTABLE_PATH ${pkgs.chromium.outPath}/bin/chromium
    '';
  };

  fauna-shell = prev.fauna-shell.override {
    # printReleaseNotes just pulls them from GitHub which is not allowed in sandbox
    preRebuild = ''
      sed -i 's|"node ./tools/printReleaseNotes"|"true"|' node_modules/faunadb/package.json
    '';
  };

  firebase-tools = prev.firebase-tools.override {
    nativeBuildInputs = lib.optionals stdenv.isDarwin  [ pkgs.xcbuild ];
  };

  flood = prev.flood.override {
    buildInputs = [ final.node-pre-gyp ];
  };

  git-ssb = prev.git-ssb.override (oldAttrs: {
    buildInputs = [ final.node-gyp-build ];
    meta = oldAttrs.meta // { broken = since "10"; };
  });

  graphite-cli = prev."@withgraphite/graphite-cli".override {
    name = "graphite-cli";
    nativeBuildInputs = [ pkgs.installShellFiles ];
    # 'gt completion' auto-detects zshell from environment variables:
    # https://github.com/yargs/yargs/blob/2b6ba3139396b2e623aed404293f467f16590039/lib/completion.ts#L45
    postInstall = ''
      installShellCompletion --cmd gt \
        --bash <($out/bin/gt completion) \
        --zsh <(ZSH_NAME=zsh $out/bin/gt completion)
    '';
  };

  graphql-language-service-cli = prev.graphql-language-service-cli.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/graphql-lsp" \
        --prefix NODE_PATH : ${final.graphql}/lib/node_modules
    '';
  };

  hsd = prev.hsd.override {
    buildInputs = [ final.node-gyp-build pkgs.unbound ];
  };

  ijavascript = prev.ijavascript.override (oldAttrs: {
    preRebuild = ''
      export npm_config_zmq_external=true
    '';
    buildInputs = oldAttrs.buildInputs ++ [ final.node-gyp-build pkgs.zeromq ];
  });

  insect = prev.insect.override (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [ pkgs.psc-package final.pulp ];
  });

  intelephense = prev.intelephense.override (oldAttrs: {
    meta = oldAttrs.meta // { license = lib.licenses.unfree; };
  });

  joplin = prev.joplin.override {
    nativeBuildInputs = [
      pkgs.pkg-config
    ] ++ lib.optionals stdenv.isDarwin [
      pkgs.xcbuild
    ];
    buildInputs = with pkgs; [
      # required by sharp
      # https://sharp.pixelplumbing.com/install
      vips

      libsecret
      final.node-gyp-build
      final.node-pre-gyp

      pixman
      cairo
      pango
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.AppKit
      darwin.apple_sdk.frameworks.Security
    ];
  };

  jsonplaceholder = prev.jsonplaceholder.override {
    buildInputs = [ nodejs ];
    postInstall = ''
      exe=$out/bin/jsonplaceholder
      mkdir -p $out/bin
      cat >$exe <<EOF
      #!${pkgs.runtimeShell}
      exec -a jsonplaceholder ${nodejs}/bin/node $out/lib/node_modules/jsonplaceholder/index.js
      EOF
      chmod a+x $exe
    '';
  };

  keyoxide = prev.keyoxide.override {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs; [
      pixman
      cairo
      pango
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreText
    ];
  };

  makam =  prev.makam.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postFixup = ''
      wrapProgram "$out/bin/makam" --prefix PATH : ${lib.makeBinPath [ nodejs ]}
      ${lib.optionalString stdenv.isLinux "patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2 \"$out/lib/node_modules/makam/makam-bin-linux64\""}
    '';
  };

  mermaid-cli = prev."@mermaid-js/mermaid-cli".override (
  if stdenv.isDarwin
  then {}
  else {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    prePatch = ''
      export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    '';
    postInstall = ''
      wrapProgram $out/bin/mmdc \
      --set PUPPETEER_EXECUTABLE_PATH ${pkgs.chromium.outPath}/bin/chromium
    '';
  });

  near-cli = prev.near-cli.override {
    nativeBuildInputs = with pkgs; [
      libusb1
      final.prebuild-install
      final.node-gyp-build
      pkg-config
    ];
  };

  node-gyp = prev.node-gyp.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    # Teach node-gyp to use nodejs headers locally rather that download them form https://nodejs.org.
    # This is important when build nodejs packages in sandbox.
    postInstall = ''
      wrapProgram "$out/bin/node-gyp" \
        --set npm_config_nodedir ${nodejs}
    '';
  };

  node-inspector = prev.node-inspector.override (oldAttrs: {
    buildInputs = [ final.node-pre-gyp ];
    meta = oldAttrs.meta // { broken = since "10"; };
  });

  node-red = prev.node-red.override {
    buildInputs = [ final.node-pre-gyp ];
  };

  node2nix = prev.node2nix.override {
    # Get latest commit for misc fixes
    src = fetchFromGitHub {
      owner = "svanderburg";
      repo = "node2nix";
      rev = "315e1b85a6761152f57a41ccea5e2570981ec670";
      sha256 = "sha256-8OxTOkwBPcnjyhXhxQEDd8tiaQoHt91zUJX5Ka+IXco=";
    };
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = let
      patches = [
        # Needed to fix packages with DOS line-endings after above patch - PR svanderburg/node2nix#314
        (fetchpatch {
          name = "convert-crlf-for-script-bin-files.patch";
          url = "https://github.com/svanderburg/node2nix/commit/91aa511fe7107938b0409a02ab8c457a6de2d8ca.patch";
          hash = "sha256-ISiKYkur/o8enKDzJ8mQndkkSC4yrTNlheqyH+LiXlU=";
        })
        # fix nodejs attr names
        (fetchpatch {
          url = "https://github.com/svanderburg/node2nix/commit/3b63e735458947ef39aca247923f8775633363e5.patch";
          hash = "sha256-pe8Xm4mjPh9oKXugoMY6pRl8YYgtdw0sRXN+TienalU=";
        })
      ];
    in ''
      ${lib.concatStringsSep "\n" (map (patch: "patch -d $out/lib/node_modules/node2nix -p1 < ${patch}") patches)}
      wrapProgram "$out/bin/node2nix" --prefix PATH : ${lib.makeBinPath [ pkgs.nix ]}
    '';
  };

  parcel = prev.parcel.override {
    buildInputs = [ final.node-gyp-build ];
    preRebuild = ''
      sed -i -e "s|#!/usr/bin/env node|#! ${nodejs}/bin/node|" node_modules/node-gyp-build/bin.js
    '';
  };

  pnpm = prev.pnpm.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];

    preRebuild = ''
      sed 's/"link:/"file:/g' --in-place package.json
    '';

    postInstall = let
      pnpmLibPath = lib.makeBinPath [
        nodejs.passthru.python
        nodejs
      ];
    in ''
      for prog in $out/bin/*; do
        wrapProgram "$prog" --prefix PATH : ${pnpmLibPath}
      done
    '';
  };

  postcss-cli = prev.postcss-cli.override (oldAttrs: {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/postcss" \
        --prefix NODE_PATH : ${final.postcss}/lib/node_modules \
        --prefix NODE_PATH : ${final.autoprefixer}/lib/node_modules
      ln -s '${final.postcss}/lib/node_modules/postcss' "$out/lib/node_modules/postcss"
    '';
    passthru.tests = {
      simple-execution = callPackage ./package-tests/postcss-cli.nix {
        inherit (final) postcss-cli;
      };
    };
    meta = oldAttrs.meta // { maintainers = with lib.maintainers; [ Luflosi ]; };
  });

  # To update prisma, please first update prisma-engines to the latest
  # version. Then change the correct hash to this package. The PR should hold
  # two commits: one for the engines and the other one for the node package.
  prisma = prev.prisma.override rec {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];

    inherit (pkgs.prisma-engines) version;

    src = fetchurl {
      url = "https://registry.npmjs.org/prisma/-/prisma-${version}.tgz";
      hash = "sha512-L9mqjnSmvWIRCYJ9mQkwCtj4+JDYYTdhoyo8hlsHNDXaZLh/b4hR0IoKIBbTKxZuyHQzLopb/+0Rvb69uGV7uA==";
    };
    postInstall = with pkgs; ''
      wrapProgram "$out/bin/prisma" \
        --set PRISMA_MIGRATION_ENGINE_BINARY ${prisma-engines}/bin/migration-engine \
        --set PRISMA_QUERY_ENGINE_BINARY ${prisma-engines}/bin/query-engine \
        --set PRISMA_QUERY_ENGINE_LIBRARY ${lib.getLib prisma-engines}/lib/libquery_engine.node \
        --set PRISMA_FMT_BINARY ${prisma-engines}/bin/prisma-fmt
    '';

    passthru.tests = {
      simple-execution = pkgs.callPackage ./package-tests/prisma.nix {
        inherit (final) prisma;
      };
    };
  };

  pulp = prev.pulp.override {
    # tries to install purescript
    npmFlags = builtins.toString [ "--ignore-scripts" ];

    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall =  ''
      wrapProgram "$out/bin/pulp" --suffix PATH : ${lib.makeBinPath [
        pkgs.purescript
      ]}
    '';
  };

  readability-cli = prev.readability-cli.override (oldAttrs: {
    # Wrap src to fix this build error:
    # > readability-cli/readable.ts: unsupported interpreter directive "#!/usr/bin/env -S deno..."
    #
    # Need to wrap the source, instead of patching in patchPhase, because
    # buildNodePackage only unpacks sources in the installPhase.
    src = pkgs.srcOnly {
      src = oldAttrs.src;
      name = oldAttrs.name;
      patchPhase = "chmod a-x readable.ts";
    };

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs; [
      pixman
      cairo
      pango
    ];
  });

  reveal-md = prev.reveal-md.override (
    lib.optionalAttrs (!stdenv.isDarwin) {
      nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
      prePatch = ''
        export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
      '';
      postInstall = ''
        wrapProgram $out/bin/reveal-md \
        --set PUPPETEER_EXECUTABLE_PATH ${pkgs.chromium.outPath}/bin/chromium
      '';
    }
  );

  rush = prev."@microsoft/rush".override {
    name = "rush";
  };

  ssb-server = prev.ssb-server.override (oldAttrs: {
    buildInputs = [ pkgs.automake pkgs.autoconf final.node-gyp-build ];
    meta = oldAttrs.meta // { broken = since "10"; };
  });

  stf = prev.stf.override (oldAttrs: {
    meta = oldAttrs.meta // { broken = since "10"; };
  });

  tailwindcss = prev.tailwindcss.override {
    plugins = [ ];
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      nodePath=""
      for p in "$out" "${final.postcss}" $plugins; do
        nodePath="$nodePath''${nodePath:+:}$p/lib/node_modules"
      done
      wrapProgram "$out/bin/tailwind" \
        --prefix NODE_PATH : "$nodePath"
      wrapProgram "$out/bin/tailwindcss" \
        --prefix NODE_PATH : "$nodePath"
      unset nodePath
    '';
    passthru.tests = {
      simple-execution = callPackage ./package-tests/tailwindcss.nix {
        inherit (final) tailwindcss;
      };
    };
  };

  teck-programmer = prev.teck-programmer.override {
    nativeBuildInputs = [ final.node-gyp-build ];
    buildInputs = [ pkgs.libusb1 ];
  };

  tedicross = prev."tedicross-git+https://github.com/TediCross/TediCross.git#v0.8.7".override {
    nativeBuildInputs = with pkgs; [ makeWrapper libtool autoconf ];
    postInstall = ''
      makeWrapper '${nodejs}/bin/node' "$out/bin/tedicross" \
        --add-flags "$out/lib/node_modules/tedicross/main.js"
    '';
  };

  thelounge-plugin-closepms = prev.thelounge-plugin-closepms.override {
    nativeBuildInputs = [ final.node-pre-gyp ];
  };

  thelounge-plugin-giphy = prev.thelounge-plugin-giphy.override {
    nativeBuildInputs = [ final.node-pre-gyp ];
  };

  thelounge-theme-flat-blue = prev.thelounge-theme-flat-blue.override {
    nativeBuildInputs = [ final.node-pre-gyp ];
    # TODO: needed until upstream pins thelounge version 4.3.1+ (which fixes dependency on old sqlite3 and transitively very old node-gyp 3.x)
    preRebuild = ''
      rm -r node_modules/node-gyp
    '';
  };

  thelounge-theme-flat-dark = prev.thelounge-theme-flat-dark.override {
    nativeBuildInputs = [ final.node-pre-gyp ];
    # TODO: needed until upstream pins thelounge version 4.3.1+ (which fixes dependency on old sqlite3 and transitively very old node-gyp 3.x)
    preRebuild = ''
      rm -r node_modules/node-gyp
    '';
  };

  ts-node = prev.ts-node.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/ts-node" \
      --prefix NODE_PATH : ${final.typescript}/lib/node_modules
    '';
  };

  tsun = prev.tsun.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/tsun" \
      --prefix NODE_PATH : ${final.typescript}/lib/node_modules
    '';
  };

  typescript-language-server = prev.typescript-language-server.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      ${pkgs.xorg.lndir}/bin/lndir ${final.typescript} $out
    '';
  };

  uppy-companion = prev."@uppy/companion".override {
    name = "uppy-companion";
  };

  vega-cli = prev.vega-cli.override {
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = with pkgs; [
      final.node-pre-gyp
      pixman
      cairo
      pango
      libjpeg
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreText
    ];
  };

  vega-lite = prev.vega-lite.override {
      postInstall = ''
        cd node_modules
        for dep in ${final.vega-cli}/lib/node_modules/vega-cli/node_modules/*; do
          if [[ ! -d ''${dep##*/} ]]; then
            ln -s "${final.vega-cli}/lib/node_modules/vega-cli/node_modules/''${dep##*/}"
          fi
        done
      '';
      passthru.tests = {
        simple-execution = callPackage ./package-tests/vega-lite.nix {
          inherit (final) vega-lite;
        };
      };
  };

  volar = final."@volar/vue-language-server".override {
    name = "volar";
  };

  wavedrom-cli = prev.wavedrom-cli.override {
    nativeBuildInputs = [ pkgs.pkg-config final.node-pre-gyp ];
    # These dependencies are required by
    # https://github.com/Automattic/node-canvas.
    buildInputs = with pkgs; [
      giflib
      pixman
      cairo
      pango
    ] ++ lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.CoreText
    ];
  };

  webtorrent-cli = prev.webtorrent-cli.override {
    buildInputs = [ final.node-gyp-build ];
  };

  wrangler = prev.wrangler.override (oldAttrs: {
    meta = oldAttrs.meta // { broken = before "16.13"; };
  });

  yaml-language-server = prev.yaml-language-server.override {
    nativeBuildInputs = [ pkgs.buildPackages.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/yaml-language-server" \
      --prefix NODE_PATH : ${final.prettier}/lib/node_modules
    '';
  };
}
