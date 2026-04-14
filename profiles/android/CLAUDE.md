# Android / LineageOS Build Profile

## Source management

- **repo** — Google's git-repo tool for managing the multi-repo Android source tree
- **git-lfs** — large file storage, required by LineageOS manifests (`repo init --git-lfs`)

## JDK

- **jdk17-openjdk** — default (LineageOS 20+ uses the JDK bundled in the source tree, but host JDK is still needed for some tooling)
- **jdk11-openjdk** — for LineageOS 18.1–19.1 host tooling
- Switch with `archlinux-java set java-17-openjdk` / `java-11-openjdk` (run as root)

## Build toolchain

- **bc**, **bison**, **flex**, **gperf** — parser/expression tools used by the kernel and AOSP build
- **ccache** — compiler cache. Env vars `USE_CCACHE=1`, `CCACHE_EXEC=/usr/bin/ccache`, `CCACHE_DIR=/work/.ccache` are preset. Run `ccache -M 50G` once before first build.
- **ninja**, **maven** — build systems used by parts of AOSP
- **protobuf** / **python-protobuf** — protocol buffers
- **elfutils**, **libelf**, **gnutls**, **openssl**, **sdl2**, **libxml2**, **libxslt** (xsltproc) — native libs required by host tools

## 32-bit compatibility (multilib)

AOSP host tools still need some 32-bit libs. Enabled via `[multilib]` in `/etc/pacman.conf`:

- **lib32-glibc**, **lib32-gcc-libs**, **lib32-zlib**, **lib32-ncurses**, **lib32-readline**
- **ncurses5-compat-libs** (AUR) — provides `libncurses.so.5`, required by some older AOSP host prebuilts

## Image / packaging

- **imagemagick**, **pngcrush** — image processing for system images
- **lzop**, **lz4**, **zip**, **unzip**, **squashfs-tools** — compression formats used in boot/recovery/system images
- **xxd** — hex dump tool (used by build scripts)
- **rsync**, **schedtool**

## Device interaction

- **android-tools** — `adb`, `fastboot`, `mkbootimg` (pulling vendor blobs from a running device, flashing builds)
- Note: `android-udev` rules and USB device passthrough are not applied inside the container. Flashing over USB is easier from the host; the container is best used for building.

## Typical flow inside the container

```sh
mkdir -p ~/android/lineage && cd ~/android/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs --no-clone-bundle
repo sync
source build/envsetup.sh
breakfast <device>
# extract or copy in vendor blobs
brunch <device>
```

## Disk / RAM expectations

- Source tree + build output: **~300–400 GB** for recent LineageOS branches
- Recommended RAM: **32 GB** for 18.1, **64 GB** for 21+
- ccache: reserve 50 GB+ on `/work/.ccache`
