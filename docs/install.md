---
next_text: UI Overview
next: /docs/overview
---

# Installing

Jump to:
* [Linux](#linux)
* [Windows](#windows)
* [Mac OS](mac-os)

## Linux

**Froggum** requires the following dependencies:

 * `valac`
 * `libgranite-dev`
 * `libvala-0.34-dev` (or higher)
 * `meson`
 * `libxml2.0-dev`

Run `meson build` to configure the build. Change to the build directory and
run `ninja` to build, and `ninja install` to install.

```
git glone https://github.com/sapoturge/froggum.git
cd froggum
meson build --prefix=/usr
cd build
ninja
sudo ninja install
```

**Froggum** can then be run by `com.github.sapoturge.froggum`.

## Windows

Unfortunately, the Granite library used by **Froggum** does not support Windows,
so neither does **Froggum** right now. I do plan to make a version without
Granite.

## Mac OS

I don't have a Mac, so I can't test it. Since Mac OS is Unix-derived, Granite
might work on it. Try following the Linux install instructions, and if it
doesn't work please [file an issue](https://github.com/sapoturge/froggum/issues/new)
so I know about it.
