#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ["MESON_INSTALL_PREFIX"], "share", "glib-2.0", "schemas")
icon_theme_dir = os.path.join(os.environ["MESON_INSTALL_PREFIX"], "share", "icons", "hicolor")

if not os.environ.get("DESTDIR"):
    print("Compiling schema...")
    subprocess.call(["glib-compile-schemas", schemadir])
    subprocess.call(["gtk-update-icon-cache", icon_theme_dir])
