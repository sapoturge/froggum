# Installing

**Froggum** requires the following dependencies:

 * `valac`
 * `libgranite-dev`
 * `libvala-0.34-dev` (or higher)
 * `meson`
 * `libxml2.0-dev`

Run `meson build` to configure the build. Change to the build directory and
run `ninja` to build, and `ninja install` to install.

```
meson build --prefix=/usr
cd build
ninja
sudo ninja install
```

**Froggum** can then be run by `com.github.sapoturge.froggum`.
