---
layout: docs
---

# Installing

**Froggum** requires the following dependencies:

 * `valac`
 * `libgranite`
 * `libgee-0.8`
 * `libvala-0.34`
 * `meson`
 * `libxml2.0`
 * [elementary themes](#installing-elementary-themes) if not running on elementary OS.

Once all dependencies are installed, you can install using the following sequence of commands:

```bash
$ git clone https://github.com/sapoturge/froggum.git
$ cd froggum
$ meson setup build
$ cd build
$ ninja
$ sudo ninja install
```

Running froggum can be done with `io.github.sapoturge.froggum`. It should also appear in the
desktop's application menu, if you have one.

## Installing on Windows

**Froggum** is known to work on Windows using MinGW, following the same instructions as for a Linux
installation. You can check the [MinGW package registry](https://packages.msys2.org/packages) to
find the names of packages to install.

## Installing elementary themes

On systems other than elementary OS, you may need the elementary stylesheet and icons for
**Froggum** to look good/correct. These can be installed from Github, following the same process as
for **Froggum** with the different package name. They may also be available from package managers;
I haven't gotten them to work there yet.

 * [elementary stylesheet](https://github.com/elementary/stylesheet)
 * [elementary icons](https://github.com/elementary/icons)

In order for Gtk to recognize these themes, you need to update or create a file named `settings.ini`
in the place Gtk looks for settings.

On Linux, this file should be at `~/.config/gtk-4.0/settings.ini`.

On Windows, this file is at `C:\Users\username\AppData\Local\gtk-4.0\settings.ini`.

The file `settings.ini` should contain the following:

```
[Settings]
gtk-theme-name=io.elementary.stylesheet.lime
gtk-icon-theme-name=elementary
```

The theme color `lime` can be substituted for `banana`, `blueberry`, `bubblegum`, `cocoa`, `grape`,
`latte`, `lime`, `mint`, `orange`, `slate`, or `strawberry`, and can optionally have a `-dark`
suffix to use the dark version of the theme.

## Mac OS 

When I briefly had access to a Mac, I was not able to install **Froggum**. I beleive this was due
to not being able to install Gtk, but it has been over a year and I don't remember for sure. If you
are able to successfully install it, let me know by posting an
[issue](https://github.com/sapoturge/froggum/issues/new) or making a
[pull request](https://github.com/sapoturge/froggum/compare) describing the steps necessary so I
can update the code and/or the documentation to make it work for others as well.

Better Mac support is planned for future releases.
