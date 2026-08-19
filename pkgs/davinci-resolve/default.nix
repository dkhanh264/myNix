{
  pkgs,
  symlinkJoin,
  makeWrapper,
  davinci-resolve,
  gcc,
  libx11,
  libxcb,
}:

let
  fixLib = pkgs.runCommand "libfix-davinci.so" {
    nativeBuildInputs = [
      gcc
      libx11
      libxcb
    ];
  } ''
    gcc -shared -fPIC -O2 -x c - -o $out -ldl -lX11 -lxcb << 'EOF_C'
    #define _GNU_SOURCE
    #include <stdio.h>
    #include <dlfcn.h>
    #include <string.h>
    #include <X11/Xlib.h>
    #include <xcb/xcb.h>

    int XSetTransientForHint(Display *display, Window w, Window prop_window) {
        return 1;
    }

    static int (*orig_XChangeProperty)(Display*, Window, Atom, Atom, int, int, const unsigned char*, int) = NULL;
    int XChangeProperty(Display *display, Window w, Atom property, Atom type, int format, int mode, const unsigned char *data, int nelements) {
        if (!orig_XChangeProperty) orig_XChangeProperty = dlsym(RTLD_NEXT, "XChangeProperty");
        char *name = XGetAtomName(display, property);
        if (name && strcmp(name, "WM_TRANSIENT_FOR") == 0) {
            XFree(name);
            return 1;
        }
        if (name) XFree(name);
        return orig_XChangeProperty(display, w, property, type, format, mode, data, nelements);
    }

    static xcb_void_cookie_t (*orig_xcb_change_property)(xcb_connection_t*, uint8_t, xcb_window_t, xcb_atom_t, xcb_atom_t, uint8_t, uint32_t, const void*) = NULL;
    xcb_void_cookie_t xcb_change_property(xcb_connection_t *c, uint8_t mode, xcb_window_t window, xcb_atom_t property, xcb_atom_t type, uint8_t format, uint32_t data_len, const void *data) {
        if (!orig_xcb_change_property) orig_xcb_change_property = dlsym(RTLD_NEXT, "xcb_change_property");
        if (property == XCB_ATOM_WM_TRANSIENT_FOR || property == 68) {
            xcb_void_cookie_t cookie = { 0 };
            return cookie;
        }
        return orig_xcb_change_property(c, mode, window, property, type, format, data_len, data);
    }
    EOF_C
  '';
in
symlinkJoin {
  name = "davinci-resolve";
  paths = [ davinci-resolve ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/davinci-resolve \
      --set QT_QPA_PLATFORM xcb \
      --set QT_XCB_GL_INTEGRATION glx \
      --set __GLX_VENDOR_LIBRARY_NAME nvidia \
      --prefix LD_PRELOAD : "${fixLib}"
  '';
}
