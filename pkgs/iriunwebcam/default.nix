{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  qt5,
  libGL,
  libpulseaudio,
  alsa-lib,
  libv4l,
  udev,
  zlib,
  glib,
  dbus,
  xorg,
  wayland,
  avahi,
  libusbmuxd,
  libimobiledevice,
  usbmuxd,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "iriunwebcam";
  version = "2.9.1";

  src = fetchurl {
    url = "https://iriun.gitlab.io/iriunwebcam-${version}.deb";

    # Lần đầu để fakeHash, build sẽ báo hash đúng.
    # Sau đó copy dòng "got: sha256-..." thay vào đây.
    hash = "sha256-slpTyetT96waR7XvcXSZDdl/Ziacc4hgM5XCxX8WC4Q=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    qt5.qtbase
    qt5.qtmultimedia
    qt5.qtwayland

    libGL
    libpulseaudio
    alsa-lib
    libv4l
    udev
    zlib
    glib
    dbus
    wayland
    avahi
    libusbmuxd
    libimobiledevice
    usbmuxd
    stdenv.cc.cc.lib

    xorg.libX11
    xorg.libxcb
    xorg.libXext
    xorg.libXrender
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXinerama
  ];

  dontBuild = true;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';
 
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a usr/* $out/

    if [ -d opt ]; then
     mkdir -p $out/opt
     cp -a opt/* $out/opt/
    fi

    mkdir -p $out/bin

    if [ -x "$out/local/bin/iriunwebcam" ]; then
     ln -sf "$out/local/bin/iriunwebcam" "$out/bin/iriunwebcam"
    fi

    if [ -f $out/share/applications/iriunwebcam.desktop ]; then
     substituteInPlace $out/share/applications/iriunwebcam.desktop \
       --replace "/usr/bin/iriunwebcam" "$out/bin/iriunwebcam" || true
    fi

    runHook postInstall
  '';

  qtWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":" (lib.makeLibraryPath [
      libusbmuxd
      libimobiledevice
      usbmuxd
    ])
    "--prefix" "PATH" ":" (lib.makeBinPath [
      libimobiledevice
      usbmuxd
    ])
  ];

  meta = with lib; {
    description = "Iriun Webcam desktop server for Linux";
    homepage = "https://iriun.com";
    platforms = platforms.linux;
  };
}
