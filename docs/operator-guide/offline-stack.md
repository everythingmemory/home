---
title: "Offline Stack"
sidebar_position: 11
kind: how-to
status: drafted
verified_against: "core branch v48-370-images: scripts/offline-images.sh save/load proven on a fresh no-egress engine, classic and containerd image stores; scripts/offline_proof.sh passes"
lede: "Running a stack with no internet access: images prepared on a connected machine, carried in as files, with the local embedding model and the local archive store."
---

The deployment option: [a single stack on one machine, with no internet needed](../../deployment-options/one-machine/).

## What runs offline as shipped

- The embedding model runs in the stack (`local-embed`), behind the model gateway, with the default route `nomic-embed-text`. It needs no key and sends nothing out.
- The gateway makes no outbound call at start: no usage report, and its price map is read from its image.
- WordNet's corpus is in the WordNet plugin's image.
- The archive is the bundled archive store, on local disk.

Do not switch the gateway to a provider's route on an offline stack: that route sends record text to the provider.

## Steps

1. **On a connected machine**, get the stack and its images. **TODO — published images.** Until they are published, clone the core repository: the stack's own images (engine, plugins, local embedding model) are built from it. Configure `local.env` as in the [quickstart](../quickstart/) steps 2 to 4, then build and pull everything:

   ```bash
   docker compose build
   docker compose pull ememory-postgres ememory-redis archive-store gateway console
   ```

2. **Save the images and their manifest.**

   ```bash
   scripts/offline-images.sh save ememory-images
   ```

   This writes `ememory-images/images.tar`, every image the compose file names, and `ememory-images/images.tsv`, which records for each service the image it uses and that image's content (its layers), read from the pinned image.

3. **Carry** the `ememory-images` folder and the repository checkout, with its `local.env`, into the isolated site.

4. **Load the images.** In the repository root:

   ```bash
   scripts/offline-images.sh load ememory-images
   ```

   It loads the images, checks each one's layers against the manifest, and writes `docker-compose.images.yml`, which names each service's image as loaded and never pulls. It needs only Docker and a shell.

5. **Start** with that file beside the compose file. Add to `local.env`:

   ```text
   COMPOSE_FILE=docker-compose.yml:docker-compose.images.yml
   ```

   then run `docker compose up -d` and check health as in the [quickstart](../quickstart/), steps 5 and 6.

Why the extra file: the compose file pins third-party images by registry digest (`name:tag@sha256:…`), and a loaded image does not always carry that digest — Docker's classic image store drops it — so compose would look for the image, not find it, and try to pull. The manifest's layer check replaces the digest check the registry would have made.

Proven on 2026-10-30 on a fresh Docker engine with no route out, on both the classic and the containerd image stores: the images loaded, the stack came up healthy, and a stored record was found by meaning.

## Proving there is no egress

`scripts/offline_proof.sh` in the core repository runs the whole proof on one connected machine: it builds and pulls, then starts the stack on a Docker network with no route out, checks that no container can reach the internet, stores three records and finds one by meaning, checks the archive holds them encrypted, deletes the database volume and checks the records and their vectors come back from the archive. By hand, on a host with no route out:

1. `curl -s http://localhost:8765/health` reports `healthy`, with `embedding.state` `ok`.
2. Store a record and find it by meaning (quickstart steps 9 and 10). A similarity result proves the local model answered.
3. `docker compose logs gateway local-embed` shows no failed outbound connection.

## Exchanging with other sites

An offline stack can still be peered with stacks it can reach on its own network; it exchanges only when connected. See [stacks in a mesh](../stacks-in-a-mesh/).
