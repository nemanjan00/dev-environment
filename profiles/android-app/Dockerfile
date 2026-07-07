FROM nemanjan00/dev:base

USER 0

# --- Toolchain versions -----------------------------------------------------
# Bump any of these to move the profile forward; they are the only knobs.
#  - ANDROID_CMDLINE_TOOLS: build number of Google's "command line tools only"
#    zip (from https://developer.android.com/studio). Only the bootstrap tools;
#    sdkmanager itself keeps them updatable at runtime.
#  - ANDROID_PLATFORM / ANDROID_BUILD_TOOLS: the SDK platform + build-tools
#    baked in. Latest stable at build time (API 36 / Android 16).
#  - GRADLE_VERSION: system Gradle. Projects with a Gradle wrapper (gradlew)
#    ignore this and use their pinned version instead.
ARG ANDROID_CMDLINE_TOOLS=14742923
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG GRADLE_VERSION=9.2.1

# JDK 17 is the Android Gradle Plugin baseline; android-tools gives adb/fastboot
# for driving a device or a host-side emulator over the network. No emulator or
# 32-bit libs here — this profile builds and tests apps, it does not build the OS
# (that is the `android` profile).
RUN pacman -Syu --noconfirm \
    jdk17-openjdk \
    android-tools && \
    archlinux-java set java-17-openjdk

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# --- Android SDK (Google's official command-line tools, no AUR) -------------
# The canonical cross-distro install: unzip the bootstrap cmdline-tools, then
# let sdkmanager pull the rest and accept licenses. Lives under /opt (outside
# every runtime bind mount, so nothing shadows it).
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_BUILD_TOOLS}:$PATH"

RUN mkdir -p "$ANDROID_HOME/cmdline-tools" && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" && \
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" && \
    rm /tmp/cmdline-tools.zip && \
    yes | sdkmanager --licenses > /dev/null && \
    sdkmanager --install \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" > /dev/null && \
    chown -R 1000:1000 "$ANDROID_HOME"

# --- System Gradle (pinned) -------------------------------------------------
# Official distribution zip; a wrapper-less project can `gradle` directly.
RUN curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    ln -s "/opt/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

# Gradle caches downloaded dependencies and wrapper distributions here; the
# docker-args.sh hook bind-mounts a host dir over it so they survive restarts.
ENV GRADLE_USER_HOME=/work/.gradle

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md

USER 1000
