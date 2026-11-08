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
  libx11,
  libxcb,
  libxext,
  libxrender,
  libxi,
  libxrandr,
  libxcursor,
  libxinerama,
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

    libx11
    libxcb
    libxext
    libxrender
    libxi
    libxrandr
    libxcursor
    libxinerama
  ];

  dontBuild = true;

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/lib
    cp -a usr/* $out/

    cat > iriun-tee.c << 'EOF'
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <fcntl.h>
    #include <linux/videodev2.h>
    #include <pthread.h>
    #include <stdarg.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <string.h>
    #include <sys/ioctl.h>
    #include <unistd.h>

    #define MAX_CLONES 8

    static int (*real_ioctl)(int, unsigned long, ...) = NULL;
    static ssize_t (*real_write)(int, const void *, size_t) = NULL;
    static int (*real_close)(int) = NULL;

    static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
    static int primary_fd = -1;
    static int clone_fds[MAX_CLONES];
    static int num_clones = 0;

    static void init_funcs(void) {
      if (!real_ioctl) real_ioctl = dlsym(RTLD_NEXT, "ioctl");
      if (!real_write) real_write = dlsym(RTLD_NEXT, "write");
      if (!real_close) real_close = dlsym(RTLD_NEXT, "close");
    }

    static void close_clones_locked(void) {
      for (int i = 0; i < num_clones; i++) {
        if (clone_fds[i] >= 0) {
          int type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
          real_ioctl(clone_fds[i], VIDIOC_STREAMOFF, &type);
          real_close(clone_fds[i]);
          clone_fds[i] = -1;
        }
      }
      num_clones = 0;
    }

    static void open_clones_if_iriun(int fd) {
      struct v4l2_capability cap;
      memset(&cap, 0, sizeof(cap));
      if (real_ioctl(fd, VIDIOC_QUERYCAP, &cap) != 0) return;
      if (strncmp((const char *)cap.card, "Iriun Webcam", 12) != 0) return;

      pthread_mutex_lock(&lock);
      close_clones_locked();
      primary_fd = fd;

      for (int i = 0; i < 64 && num_clones < MAX_CLONES; i++) {
        char path[32];
        snprintf(path, sizeof(path), "/dev/video%d", i);
        int cfd = open(path, O_RDWR);
        if (cfd < 0) continue;

        struct v4l2_capability ccap;
        memset(&ccap, 0, sizeof(ccap));
        if (real_ioctl(cfd, VIDIOC_QUERYCAP, &ccap) == 0 &&
            strncmp((const char *)ccap.card, "Iriun Cam ", 10) == 0) {
          clone_fds[num_clones++] = cfd;
        } else {
          real_close(cfd);
        }
      }
      pthread_mutex_unlock(&lock);
    }

    int ioctl(int fd, unsigned long req, ...) {
      init_funcs();
      va_list ap;
      va_start(ap, req);
      void *arg = va_arg(ap, void *);
      va_end(ap);

      if (req == VIDIOC_G_FMT) {
        open_clones_if_iriun(fd);
      }

      int ret = real_ioctl(fd, req, arg);

      if (fd >= 0 && fd == primary_fd && arg != NULL) {
        if (req == VIDIOC_G_FMT || req == VIDIOC_S_FMT ||
            req == VIDIOC_S_PARM || req == VIDIOC_STREAMON ||
            req == VIDIOC_STREAMOFF) {
          size_t sz = _IOC_SIZE(req);
          if (sz > 0 && sz <= 512) {
            pthread_mutex_lock(&lock);
            if (fd == primary_fd) {
              for (int i = 0; i < num_clones; i++) {
                if (clone_fds[i] >= 0) {
                  uint8_t tmp[512];
                  memcpy(tmp, arg, sz);
                  real_ioctl(clone_fds[i], req, tmp);
                }
              }
            }
            pthread_mutex_unlock(&lock);
          }
        }
      }
      return ret;
    }

    ssize_t write(int fd, const void *buf, size_t count) {
      init_funcs();
      ssize_t ret = real_write(fd, buf, count);
      if (fd >= 0 && fd == primary_fd && ret > 0) {
        pthread_mutex_lock(&lock);
        if (fd == primary_fd) {
          for (int i = 0; i < num_clones; i++) {
            if (clone_fds[i] >= 0) {
              real_write(clone_fds[i], buf, count);
            }
          }
        }
        pthread_mutex_unlock(&lock);
      }
      return ret;
    }

    int close(int fd) {
      init_funcs();
      if (fd >= 0 && fd == primary_fd) {
        pthread_mutex_lock(&lock);
        if (fd == primary_fd) {
          close_clones_locked();
          primary_fd = -1;
        }
        pthread_mutex_unlock(&lock);
      }
      return real_close(fd);
    }
    EOF

    $CC -shared -fPIC -O2 iriun-tee.c -o $out/lib/libiriun-tee.so -ldl -lpthread

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
       --replace "/usr/local/bin/iriunwebcam" "$out/bin/iriunwebcam" \
       --replace "/usr/bin/iriunwebcam" "$out/bin/iriunwebcam" || true
    fi

    runHook postInstall
  '';

  qtWrapperArgs = [
    "--prefix" "LD_PRELOAD" ":" "${placeholder "out"}/lib/libiriun-tee.so"
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
