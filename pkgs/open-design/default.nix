{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm_10,
  nodejs_24,
  node-gyp,
  python3,
  gnumake,
  pkg-config,
  autoPatchelfHook,
  makeWrapper,
  patchelf,
  zlib,
  ffmpeg,
  poppler-utils,
  zenity,
  yt-dlp,
  xdg-utils,
  chromium,
  git,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "open-design";
  version = "0.27.1";

  src = fetchFromGitHub {
    owner = "nexu-io";
    repo = "open-design";
    tag = "open-design-v${finalAttrs.version}";
    hash = "sha256-xUVxaIjud9oLeb64FejpZXg14diZOajjmXh+bfFxVh4=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-d4RWM+XhJkPzLVw/vxupqKPag5zbg70xsLTe+2BfKaw=";
  };

    nativeBuildInputs = [
    autoPatchelfHook
    gnumake
    makeWrapper
    node-gyp
    nodejs_24
    patchelf
    pkg-config
    pnpmConfigHook
    pnpm_10
    python3
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libcudart.so.*"
    "libcublas.so.*"
    "libcublasLt.so.*"
    "libcudnn*.so.*"
    "libcuda.so.*"
    "libnvinfer*.so.*"
  ];

  env = {
    CI = "true";
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    ONNXRUNTIME_NODE_INSTALL_CUDA = "skip";
    npm_config_nodedir = "${nodejs_24}";
  };

  preBuild = ''
    # Remove foreign-platform prebuilds before autoPatchelf scans node_modules
    find node_modules -type d \( \
      -name "darwin-*" -o -name "win32-*" -o \
      -name "linux-arm*" -o -name "linux-ia32*" -o \
      -name "linux-ppc64*" -o -name "linux-riscv64*" -o -name "linux-s390x*" \
    \) -prune -exec rm -rf '{}' +
    find node_modules -type d -name prebuilds -exec sh -c '
      for dir do
        for sub in "$dir"/*; do
          [ -d "$sub" ] || continue
          case "$(basename "$sub")" in
            linux-x64) ;;
            *) rm -rf "$sub" ;;
          esac
        done
      done
    ' sh {} +
    find node_modules -path "*/onnxruntime-node/bin/napi-v*" -type d -exec sh -c '
      for dir do
        rm -rf "$dir/darwin" "$dir/win32" "$dir/linux/arm64"
      done
    ' sh {} +

    autoPatchelf node_modules

    local sqliteDir
    sqliteDir="$(realpath apps/daemon/node_modules/better-sqlite3)"
    (cd "$sqliteDir" && node-gyp rebuild --release --nodedir=${nodejs_24})
    node -e "require('./apps/daemon/node_modules/better-sqlite3')(':memory:').close()"

    if [ -e apps/daemon/node_modules/node-pty ]; then
      local ptyDir
      ptyDir="$(realpath apps/daemon/node_modules/node-pty)"
      if ! node -e "require('./apps/daemon/node_modules/node-pty')" 2>/dev/null; then
        (cd "$ptyDir" && node-gyp rebuild --release --nodedir=${nodejs_24})
      fi
    fi
  '';

  buildPhase = ''
    runHook preBuild

    node ./scripts/postinstall.mjs
    pnpm --offline --filter @open-design/web build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    local appRoot="$out/lib/open-design"
    mkdir -p "$appRoot/apps/daemon" "$appRoot/apps/web" "$appRoot/node_modules" "$out/bin"

    cp -a apps/daemon/bin "$appRoot/apps/daemon/bin"
    cp -a apps/daemon/dist "$appRoot/apps/daemon/dist"
    cp -a apps/daemon/node_modules "$appRoot/apps/daemon/node_modules"
    cp -a apps/daemon/package.json "$appRoot/apps/daemon/package.json"

    cp -a packages "$appRoot/packages"
    rm -rf "$appRoot"/packages/*/src "$appRoot"/packages/*/tests

    cp -a node_modules/.pnpm "$appRoot/node_modules/.pnpm"
    if [ -f node_modules/.modules.yaml ]; then
      cp -a node_modules/.modules.yaml "$appRoot/node_modules/.modules.yaml"
    fi

    cp -a apps/web/out "$appRoot/apps/web/out"
    cp -a skills "$appRoot/skills"
    cp -a design-templates "$appRoot/design-templates"
    cp -a design-systems "$appRoot/design-systems"
    cp -a craft "$appRoot/craft"
    cp -a prompt-templates "$appRoot/prompt-templates"
    cp -a data "$appRoot/data"
    mkdir -p "$appRoot/assets" "$appRoot/plugins"
    cp -a assets/frames "$appRoot/assets/frames"
    cp -a assets/community-pets "$appRoot/assets/community-pets"
    cp -a plugins/_official "$appRoot/plugins/_official"
    cp -a plugins/registry "$appRoot/plugins/registry"

    # Strip unneeded build sources, foreign prebuilds, and broken workspace symlinks
    find "$appRoot/node_modules" -type d \( \
      -name "darwin-*" -o -name "win32-*" -o \
      -name "linux-arm*" -o -name "linux-ia32*" -o \
      -name "linux-ppc64*" -o -name "linux-riscv64*" -o -name "linux-s390x*" -o \
      -name test -o -name tests -o -name "__tests__" -o \
      -name docs -o -name doc -o -name ".github" \
    \) -prune -exec rm -rf '{}' +
    rm -rf "$appRoot"/node_modules/.pnpm/better-sqlite3@*/node_modules/better-sqlite3/{deps,src,build/Release/obj.target}
    rm -rf "$appRoot"/node_modules/.pnpm/node-pty@*/node_modules/node-pty/{deps,src,build/Release/obj.target}
    find "$appRoot/node_modules" -type f \( \
      -name "*.map" -o -name "*.tsbuildinfo" -o -name "binding.gyp" \
    \) -delete
    find "$appRoot" -xtype l -delete
    test -e "$appRoot/apps/daemon/node_modules/better-sqlite3"

    # Strip preBuild RPATHs pointing into /build and re-patchelf against $out
    find "$appRoot/node_modules" -type f \( -name "*.node" -o -name "*.so" -o -name "*.so.*" \) \
      -exec patchelf --remove-rpath '{}' \; 2>/dev/null || true
    autoPatchelf "$appRoot/node_modules"

    chmod +x "$appRoot/apps/daemon/dist/cli.js"
    sed -i "1s|^#!.*|#!${nodejs_24}/bin/node|" "$appRoot/apps/daemon/dist/cli.js"

    cat > "$out/bin/.open-design-unwrapped" <<'EOF'
    #!@bash@/bin/bash
    set -euo pipefail
    if [ -z "''${OD_DATA_DIR:-}" ]; then
      export OD_DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/open-design"
    fi
    exec "@nodejs@/bin/node" "@out@/lib/open-design/apps/daemon/dist/cli.js" "$@"
    EOF
    substituteInPlace "$out/bin/.open-design-unwrapped" \
      --replace-fail "@bash@" "${bash}" \
      --replace-fail "@nodejs@" "${nodejs_24}" \
      --replace-fail "@out@" "$out"
    chmod +x "$out/bin/.open-design-unwrapped"

    makeWrapper "$out/bin/.open-design-unwrapped" "$out/bin/open-design" \
      --set-default OD_NODE_BIN "${nodejs_24}/bin/node" \
      --set-default HYPERFRAMES_BROWSER_PATH "${chromium}/bin/chromium" \
      --set-default HYPERFRAMES_FFMPEG_PATH "${ffmpeg}/bin/ffmpeg" \
      --suffix PATH : "${
        lib.makeBinPath [
          nodejs_24
          ffmpeg
          poppler-utils
          zenity
          yt-dlp
          xdg-utils
          git
          bash
        ]
      }"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    test -f "$out/lib/open-design/apps/web/out/index.html"
    "${nodejs_24}/bin/node" -e "require('$out/lib/open-design/apps/daemon/node_modules/better-sqlite3')(':memory:').close()"
    "${nodejs_24}/bin/node" -e "require('$out/lib/open-design/apps/daemon/node_modules/node-pty')"
    "$out/bin/open-design" --help >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "Local-first collaborative AI design agent workspace (daemon + web UI)";
    homepage = "https://github.com/nexu-io/open-design";
    license = lib.licenses.asl20;
    mainProgram = "open-design";
    platforms = [ "x86_64-linux" ];
  };
})
