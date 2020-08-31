#! /usr/bin/env python

import os
import subprocess

schemadir = os.path.join(os.environ["MESON_INSTALL_PREFIX"], "share", "glib-2.0", "schemas")

if not os.environ.get("DESTDIR"):
    print("Compiling schema...")
    subprocess.call(["glib-compile-schemas", schemadir])
