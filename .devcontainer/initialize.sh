#!/usr/bin/env bash
# Runs on the host before the container is created or started (devcontainer.json initializeCommand).
set -uo pipefail

cd "$(dirname "$0")"

# Allow local (same-uid) clients to use the host X server, so XWayland/X11 apps in the container can open windows.
if command -v xhost >/dev/null 2>&1; then
  xhost +SI:localuser:"$(id -un)" >/dev/null || true
fi

# Record the host's IANA time-zone name for post-start.sh. Bind-mounting /etc/localtime does not work: the container's
# /etc/localtime is a symlink to Etc/UTC, so the mount replaces the UTC zone file with the host's data. glibc then shows
# local time, but libstdc++'s std::chrono::current_zone() reads the symlink name and reports UTC.
tz="$(timedatectl show --property=Timezone --value 2>/dev/null || true)"
if [[ -z "${tz}" ]]; then
  tz="$(readlink /etc/localtime 2>/dev/null | sed -n 's|.*/zoneinfo/||p')"
fi
printf '%s\n' "${tz:-Etc/UTC}" >.host-timezone
