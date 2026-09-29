{ pkgs, ... }:

let
  camera-watcher = pkgs.writeScriptBin "camera-watcher" ''
    #!${pkgs.python3}/bin/python3
    import os
    import sys
    import time
    import glob
    import ctypes
    import struct
    import threading
    import subprocess

    libc = ctypes.CDLL("libc.so.6")
    inotify_init1 = libc.inotify_init1
    inotify_add_watch = libc.inotify_add_watch

    IN_OPEN = 0x00000020
    IN_CREATE = 0x00000100

    last_applied = {}
    COOLDOWN = 4.0

    def apply_preset(device):
        now = time.time()
        last = last_applied.get(device, 0)
        if now - last < COOLDOWN:
            return
        last_applied[device] = now

        def _worker():
            # Delay 1.0s to allow WebRTC/Chromium initialization to finish
            time.sleep(1.0)
            try:
                print(f"[camera-watcher] Applying cameractrls preset_1 for {device}")
                subprocess.run(["${pkgs.cameractrls-gtk4}/bin/cameractrls", "-d", device, "-c", "preset=load_1"], check=False)
            except Exception as e:
                print(f"[camera-watcher] Error applying preset: {e}")

        threading.Thread(target=_worker, daemon=True).start()

    def main():
        fd = inotify_init1(0)
        if fd < 0:
            sys.exit(1)

        # Initial apply on startup for existing devices
        for dev in glob.glob("/dev/video*"):
            apply_preset(dev)

        libc.inotify_add_watch(fd, b"/dev", IN_CREATE)

        watches = {}
        for dev in glob.glob("/dev/video*"):
            wd = libc.inotify_add_watch(fd, dev.encode(), IN_OPEN)
            if wd >= 0:
                watches[wd] = dev

        while True:
            try:
                buf = os.read(fd, 2048)
            except Exception:
                break
            if not buf:
                break
            pos = 0
            while pos + 16 <= len(buf):
                wd, mask, cookie, length = struct.unpack_from("iIII", buf, pos)
                pos += 16
                name = ""
                if length > 0:
                    name = buf[pos:pos+length].decode("utf-8", errors="ignore").rstrip("\x00")
                    pos += length

                if mask & IN_CREATE:
                    if name.startswith("video"):
                        dev = f"/dev/{name}"
                        time.sleep(1.0)
                        new_wd = libc.inotify_add_watch(fd, dev.encode(), IN_OPEN)
                        if new_wd >= 0:
                            watches[new_wd] = dev
                        apply_preset(dev)
                elif mask & IN_OPEN:
                    dev = watches.get(wd)
                    if dev:
                        apply_preset(dev)

    if __name__ == "__main__":
        main()
  '';

  cam-fix = pkgs.writeShellScriptBin "cam-fix" ''
    echo "Reloading camera settings from preset 1..."
    ${pkgs.cameractrls-gtk4}/bin/cameractrls -d /dev/video0 -c preset=load_1
    echo "Done!"
  '';
in
{
  home.packages = with pkgs; [
    cameractrls-gtk4
    camera-watcher
    cam-fix
  ];

  systemd.user.services.camera-watcher = {
    Unit = {
      Description = "Camera Settings Auto-Persistence Daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${camera-watcher}/bin/camera-watcher";
      Restart = "always";
      RestartSec = "3s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
