# Android App Development Profile

This profile builds, tests, and packages **Android apps** (Gradle/Kotlin/Java).
It is deliberately distinct from the `android` profile, which builds the OS
itself (AOSP/LineageOS). If you are here to compile an app, sign an APK/AAB, or
run its test suite, you are in the right place.

## SDK

- **ANDROID_HOME** / **ANDROID_SDK_ROOT** = `/opt/android-sdk` (baked into the
  image, outside every bind mount so nothing shadows it).
- Installed via Google's official command-line tools — **no AUR**. Baked in:
  - **platform-tools** — `adb`, `fastboot` (also on `PATH`).
  - **platforms;android-36** — the compile/target SDK (Android 16).
  - **build-tools;36.0.0** — `aapt2`, `apksigner`, `zipalign`, `d8`, on `PATH`.
- **sdkmanager** and **avdmanager** are on `PATH` (`cmdline-tools/latest/bin`).
  SDK licenses are already accepted, so you can pull more on demand:
  ```sh
  sdkmanager --install "platforms;android-34" "build-tools;34.0.0"
  sdkmanager --list_installed
  ```
  Note: packages installed at runtime land in the baked `/opt/android-sdk` and
  are **not** persisted across container runs (only Gradle's caches are — see
  below). To make an extra platform permanent, bump the `ARG`s in the profile
  Dockerfile and rebuild.

## JDK

- **jdk17-openjdk** is the default (`JAVA_HOME=/usr/lib/jvm/java-17-openjdk`) —
  the Android Gradle Plugin baseline. Switch with `archlinux-java set` (as root)
  only if a project pins a different JDK.

## Build tooling

- **System Gradle 9.2.1** (the 9.2 line) at `/usr/local/bin/gradle` for
  wrapper-less projects.
- **Almost every project ships a Gradle wrapper** — prefer `./gradlew` over the
  system `gradle`; the wrapper downloads and uses the version the project pins,
  which is what CI and other developers use. The system Gradle is only a
  bootstrap for projects that lack a wrapper.
- **GRADLE_USER_HOME** = `/work/.gradle`, bind-mounted from the host (see
  persistence) so downloaded dependencies and wrapper distributions survive
  across container runs — the first build is slow, subsequent ones are not.

## Typical flow inside the container

The project lives in `/work/project` (bind-mounted from the host cwd).

```sh
cd /work/project
./gradlew assembleDebug          # build a debug APK
./gradlew test                   # JVM unit tests
./gradlew lint                   # Android lint
./gradlew connectedAndroidTest   # instrumented tests (needs a device — see below)
./gradlew bundleRelease          # build a release AAB
```

## Device / emulator interaction

There is **no emulator in this image** — emulators want KVM and a lot of disk,
and are far easier to run on the host. Instead, `adb` connects out to a device
or emulator you run elsewhere:

- **Physical device**: USB passthrough isn't wired into the container, so run
  `adb` from the host for USB. Over the network, `adb connect <device-ip>:5555`
  works from inside the container once the device has `adb tcpip 5555` enabled.
- **Host emulator**: start the AVD on the host, then from the container
  `adb connect host.docker.internal:5555` (the emulator's adb port), or run the
  host's `adb -a` server and point `ADB_SERVER_SOCKET` at it.
- `connectedAndroidTest` / `connectedCheck` will use whatever `adb devices`
  shows once connected.

## Signing

- **apksigner** (build-tools) signs and verifies APKs; **jarsigner** (JDK) and
  Gradle signing configs cover AABs. Generate a keystore with `keytool`
  (`keytool -genkeypair -v -keystore my.keystore ...`). Keep keystores in the
  project (persisted) or a mounted dir — anything outside `/work/project` and
  `/work/.gradle` is ephemeral.

## What's deliberately *not* here

- **No emulator / system images** — run them on the host; connect with `adb`.
- **No AOSP/ROM toolchain** (repo, ccache, 32-bit multilib libs, kernel build
  deps) — that is the separate `android` profile.
- **No Android Studio GUI** — this is a headless CLI environment; drive Gradle
  and the SDK command-line tools directly.

## Persistence

The profile ships a `docker-args.sh` hook the launcher picks up automatically:
it bind-mounts `~/.cache/android-app/gradle` on the host to `/work/.gradle` in
the container, so Gradle's dependency and wrapper caches persist. For a manual
`docker run`, add `-v ~/.cache/android-app/gradle:/work/.gradle` yourself.
