#!/usr/bin/env python3
import os
import glob
import json

def collect_app_dirs(home):
    dirs = {
        '/usr/share/applications',
        '/usr/local/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.local/share/applications',
        f'{home}/.nix-profile/share/applications',
        f'/etc/profiles/per-user/{os.path.basename(home)}/share/applications',
        '/run/current-system/sw/share/applications',
        '/nix/var/nix/profiles/default/share/applications',
    }

    xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "")
    for base in xdg_data_dirs.split(":"):
        if base:
            dirs.add(os.path.join(base, "applications"))

    return [d for d in dirs if os.path.exists(d)]

def fetch_apps():
    apps = {}
    home = os.path.expanduser('~')

    dirs = collect_app_dirs(home)

    for d in dirs:
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8') as file:
                    app = {'name': '', 'exec': '', 'icon': ''}
                    is_desktop = False
                    no_display = False
                    hidden = False
                    
                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False
                            
                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                # Strip %u, %f, and @@ placeholders
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                            elif line.startswith('Hidden=true') or line.startswith('Hidden=1'):
                                hidden = True
                                
                    if app['name'] and app['exec'] and not no_display and not hidden:
                        apps[app['name']] = app
            except Exception:
                pass
                
    # Sort alphabetically and return as JSON
    res = list(apps.values())
    res.sort(key=lambda x: x['name'].lower())
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()

