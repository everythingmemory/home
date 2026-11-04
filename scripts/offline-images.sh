#!/bin/sh
# Copyright (c) 2026 ConcurAI
# SPDX-License-Identifier: BUSL-1.1
# Carry the stack's images to a machine with no internet access.
#
#   scripts/offline-images.sh save BUNDLE_DIR [compose args...]
#   scripts/offline-images.sh load BUNDLE_DIR
#
# WHERE THE IMAGES COME FROM: eMemory's own from the GitHub Container Registry
# (ghcr.io/everythingmemory/<name>, public, amd64 and arm64), the rest from
# their publishers; the compose file pins each by digest.
#
# SAVE runs on a connected machine, in the repository root, after the images
# are pulled (`docker compose pull`, on a machine of the offline machine's
# architecture; see "Running with no internet access" in docs/install.md) — or
# built, with docker-compose.build.yml among the compose args. It writes
# BUNDLE_DIR/images.tar — every image the
# compose file names, saved as ememory-offline/<name>:<tag> — and
# BUNDLE_DIR/images.tsv: one line per service,
# `service <TAB> reference <TAB> saved name <TAB> layers`,
# the layers being the image's content (its layer diff ids), the same on any
# Docker. Compose args (default
# `-f docker-compose.yml`) choose the files; local.env must be in place, as
# for `up`. Needs python3.
#
# LOAD runs on the offline machine, in the repository root, with nothing but
# Docker and a POSIX shell. It loads the images, checks each one's layers are
# exactly those recorded from the pinned image, and writes
# docker-compose.images.yml — an overlay naming each service's image by the
# name and tag it was saved under, never pulled. Start the stack with it:
#
#   COMPOSE_FILE=docker-compose.yml:docker-compose.images.yml   (in local.env)
#
# WHY AN OVERLAY. The compose file pins third-party images by registry digest
# (`name:tag@sha256:…`). A loaded image does not carry its registry digest on
# Docker's classic image store — the digest belongs to the registry — so after
# `docker load` such a reference may not resolve, and compose would try to
# pull it. Image ids are no substitute: the classic and containerd image
# stores number the same image differently. The layer diff ids are the
# image's content on both, so load checks them against what save read from
# the pinned image, and the overlay names the image it checked.
set -eu

usage() { sed -n '4,5p' "$0" | sed 's/^# //' >&2; exit 2; }
[ $# -ge 2 ] || usage
cmd=$1; bundle=$2; shift 2
TAB=$(printf '\t')

case "$cmd" in
save)
    [ $# -gt 0 ] || set -- -f docker-compose.yml
    mkdir -p "$bundle"
    docker compose "$@" config --format json | python3 -c "
import json, sys
for name, svc in sorted(json.load(sys.stdin)['services'].items()):
    print(name, svc['image'])" >"$bundle/.services"
    : >"$bundle/images.tsv"
    missing=""
    names=""
    in_use=""
    [ -f docker-compose.images.yml ] && in_use=$(sed -n 's/^    image: //p' docker-compose.images.yml)
    cleanup() {
        for n in $names; do
            case " $(echo $in_use) " in *" $n "*) continue ;; esac
            docker image rm "$n" >/dev/null 2>&1 || true
        done
    }
    trap cleanup EXIT
    while read -r service ref; do
        if layers=$(docker image inspect -f '{{join .RootFS.Layers ","}}' "$ref" 2>/dev/null); then
            name=${ref%%@*}
            case "${name##*/}" in *:*) ;; *) name="$name:latest" ;; esac
            name="ememory-offline/$name"
            docker tag "$ref" "$name"
            printf '%s\t%s\t%s\t%s\n' "$service" "$ref" "$name" "$layers" >>"$bundle/images.tsv"
            names="$names $name"
        else
            missing="$missing
  $ref"
        fi
    done <"$bundle/.services"
    rm -f "$bundle/.services"
    if [ -n "$missing" ]; then
        echo "not on this machine — pull first (docker compose pull):$missing" >&2
        exit 1
    fi
    names=$(echo $names | tr ' ' '\n' | sort -u | tr '\n' ' ')
    docker save -o "$bundle/images.tar" $names
    echo "saved $(echo $names | wc -w | tr -d ' ') images for $(wc -l <"$bundle/images.tsv" | tr -d ' ') services to $bundle"
    ;;
load)
    if [ ! -f "$bundle/images.tar" ] || [ ! -f "$bundle/images.tsv" ]; then
        echo "no images.tar and images.tsv in $bundle" >&2; exit 1
    fi
    docker load -i "$bundle/images.tar" >/dev/null
    out=docker-compose.images.yml
    tmp=$(mktemp "${out}.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    {
        echo "# Written by scripts/offline-images.sh load: each service's image by the"
        echo "# name it was saved under, its layers checked against the pinned image."
        echo "services:"
    } >"$tmp"
    while IFS="$TAB" read -r service ref name layers; do
        got=$(docker image inspect -f '{{join .RootFS.Layers ","}}' "$name" 2>/dev/null) || {
            echo "$name ($ref) did not arrive" >&2; exit 1; }
        if [ "$got" != "$layers" ]; then
            echo "$name is not the image saved for $ref: its layers differ" >&2; exit 1
        fi
        printf '  %s:\n    image: %s\n    pull_policy: never\n' "$service" "$name" >>"$tmp"
    done <"$bundle/images.tsv"
    mv "$tmp" "$out"
    echo "loaded; wrote $out — start with COMPOSE_FILE=docker-compose.yml:$out"
    ;;
*) usage ;;
esac
