# Silica development container.
#
# Base: Microsoft's Ubuntu 26.04 ("resolute") dev container image, which provides the non-root `vscode` user.
# Toolchain: GCC 16 (C++26 static reflection) from the Ubuntu archive, LLVM 23 tooling from apt.llvm.org.
FROM mcr.microsoft.com/devcontainers/base:ubuntu26.04

ARG LLVM_VERSION=23
ARG GCC_VERSION=16
ARG TRACY_VERSION=v0.15.0

ENV DEBIAN_FRONTEND=noninteractive

# --- Core toolchain -------------------------------------------------------------------------------------------------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gcc-${GCC_VERSION} g++-${GCC_VERSION} \
      cmake ninja-build make pkg-config ccache gdb git git-lfs \
      ca-certificates curl wget gnupg unzip xz-utils python3 python3-pip \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 100 \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-${GCC_VERSION} 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-${GCC_VERSION} 100 \
 && rm -rf /var/lib/apt/lists/*

# --- LLVM tooling (clangd, clang-tidy, clang-format) ----------------------------------------------------------------
# Ubuntu 26.04 ships LLVM 21/22; apt.llvm.org carries the latest release.
RUN wget -qO /etc/apt/trusted.gpg.d/apt.llvm.org.asc https://apt.llvm.org/llvm-snapshot.gpg.key \
 && echo "deb http://apt.llvm.org/resolute/ llvm-toolchain-resolute-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      clangd-${LLVM_VERSION} clang-tidy-${LLVM_VERSION} clang-format-${LLVM_VERSION} clang-tools-${LLVM_VERSION} \
 && for tool in clangd clang-tidy clang-format run-clang-tidy clang-apply-replacements; do \
      if [ -e /usr/bin/${tool}-${LLVM_VERSION} ]; then \
        update-alternatives --install /usr/bin/${tool} ${tool} /usr/bin/${tool}-${LLVM_VERSION} 100; \
      fi; \
    done \
 && rm -rf /var/lib/apt/lists/*

# --- SDL3 / OpenGL build and runtime dependencies -------------------------------------------------------------------
# SDL3 is built from source by CMake FetchContent (ADR-0002); these are the system headers it compiles against so that
# both the X11 and Wayland video drivers, and the audio back ends, are available.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev libxtst-dev \
      libxkbcommon-dev libwayland-dev wayland-protocols libdecor-0-dev \
      libdecor-0-plugin-1-gtk \
      libegl-dev libgl-dev libgles-dev libglvnd-dev libdrm-dev libgbm-dev \
      libasound2-dev libpulse-dev libpipewire-0.3-dev libdbus-1-dev libudev-dev libusb-1.0-0-dev \
      libfreetype-dev libharfbuzz-dev libfontconfig-dev \
      libgl1 libegl1 libgles2 libglx-mesa0 libegl-mesa0 libgl1-mesa-dri mesa-utils mesa-vulkan-drivers \
      fonts-dejavu-core fonts-noto-core fonts-jetbrains-mono \
 && rm -rf /var/lib/apt/lists/*

# --- Headless display and UI automation (lets Claude "see" and drive the UI) ----------------------------------------
# Xvfb provides a virtual X server, xdotool injects input, ImageMagick/xwd capture screenshots, and weston can provide
# a headless Wayland compositor when testing the Wayland path.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xvfb xauth x11-utils x11-xserver-utils x11-apps xdotool imagemagick wmctrl openbox weston \
 && rm -rf /var/lib/apt/lists/*

# --- Tracy profiler GUI ---------------------------------------------------------------------------------------------
# The client is pulled into the build by FetchContent; the server/viewer is built here once so it is always available
# as `tracy-profiler` inside the container.
RUN apt-get update \
 && apt-get install -y --no-install-recommends libcapstone-dev libtbb-dev libglfw3-dev \
 && rm -rf /var/lib/apt/lists/* \
 && git clone --depth 1 --branch ${TRACY_VERSION} https://github.com/wolfpld/tracy.git /tmp/tracy \
 && cmake -S /tmp/tracy/profiler -B /tmp/tracy/build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLEGACY=ON \
 && cmake --build /tmp/tracy/build \
 && install -m 0755 /tmp/tracy/build/tracy-profiler /usr/local/bin/tracy-profiler \
 && rm -rf /tmp/tracy /root/.cache

# Runtime directory for the Wayland socket that devcontainer.json bind-mounts from the host.
RUN mkdir -p /tmp/runtime-vscode && chown vscode:vscode /tmp/runtime-vscode && chmod 0700 /tmp/runtime-vscode

# ~/.cache must belong to vscode before the ccache volume is mounted inside it, or Mesa and NVIDIA cannot create their
# shader caches there.
RUN mkdir -p /home/vscode/.cache/ccache && chown -R vscode:vscode /home/vscode/.cache

ENV CC=gcc-${GCC_VERSION} \
    CXX=g++-${GCC_VERSION} \
    CCACHE_DIR=/home/vscode/.cache/ccache \
    XDG_RUNTIME_DIR=/tmp/runtime-vscode
