---
next-text: UI Overview
next: overview
layout: docs
version: 0.2
---

# Installing

Jump to:
* [Linux](#linux)
* [Windows](#windows)
* [Mac OS](#mac-os)

## Linux

**Froggum** requires the following dependencies:

 * `valac`
 * `libgranite-dev` (optional for `feature-windows` branch)
 * `libgee-0.8`
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

The `Granite` library does not support running on Windows. The
[feature-windows](https://github.com/sapoturge/froggum/tree/feature-windows)
branch does support being compiled and run on Windows using MinGW (and probably
Cygwin, but I haven't tested it.). It requires all dependencies above except
`libgranite-dev`. The process is otherwise almost identical:

```
git clone https://github.com/sapoturge/froggum.git
cd froggum
git checkout feature-windows
meson build --prefix=/usr
cd build
ninja
ninja install
```

**Froggum** can then be run by `com.github.sapoturge.froggum`, as usual.

## Mac OS

I was not able to install **Froggum** while I had access to a Mac, but you are welcome to try.
Mac is Unix-derived, so `Granite` might work on it. Try following the instructions
for [Linux](#linux) above, and if that doesn't work install as for [Windows](#windows).
These two branches will be merged eventually, without `Granite`, so the process
will be simpler everywhere.
