# Offline Stack

Running a stack with no internet access: images prepared on a connected machine, carried in as files, with the local embedding model and the archive in a local folder.

The deployment option: [a single stack on one machine, with no internet needed](../deployment-options/one-machine.md).

## What runs offline as shipped

- The embedding model runs in the stack (`local-embed`), behind the model gateway, with the default route `nomic-embed-text`. It needs no key and sends nothing out.
- The gateway makes no outbound call at start: no usage report, and its price map is read from its image.
- WordNet's corpus is in the WordNet plugin's image.
- The archive is a folder on local disk, written by the engine.

Do not switch the gateway to a provider's route on an offline stack: that route sends record text to the provider.

## Steps

1. **On a connected machine of the same architecture as the isolated one** (amd64 or arm64), get the stack and its images. Download the latest release of [everythingmemory/home](https://github.com/everythingmemory/home/releases) and unpack it, write `.env` with `./e.sh init` as in the [quickstart](quickstart.md) steps 2 and 3, then pull every image the compose file pins:

   ```bash
   docker compose pull
   ```

2. **Save the images and their manifest.**

   ```bash
   scripts/offline-images.sh save ememory-images
   ```

   This writes `ememory-images/images.tar`, every image the compose file names, and `ememory-images/images.tsv`, which records for each service the image it uses and that image's content (its layers), read from the pinned image.

3. **Carry** the `ememory-images` folder and the unpacked release, with its `.env` and `conf/`, into the isolated site, and make the `ARCHIVE_DIR` folder `.env` names there (`mkdir -p` that path): a missing folder is refused.

4. **Load the images.** In the release folder:

   ```bash
   scripts/offline-images.sh load ememory-images
   ```

   It loads the images, checks each one's layers against the manifest, and writes `docker-compose.images.yml`, which names each service's image as loaded and never pulls. It needs only Docker and a shell.

5. **Start** with that file beside the compose file. Add to `.env`:

   ```text
   COMPOSE_FILE=docker-compose.yml:docker-compose.images.yml
   ```

   then run `docker compose up -d` and check health as in the [quickstart](quickstart.md), steps 4 and 5.

Why the extra file: the compose file pins third-party images by registry digest (`name:tag@sha256:…`), and a loaded image does not always carry that digest — Docker's classic image store drops it — so compose would look for the image, not find it, and try to pull. The manifest's layer check replaces the digest check the registry would have made.

Proven on 2026-10-30 on a fresh Docker engine with no route out, on both the classic and the containerd image stores: the images loaded, the stack came up healthy, and a stored record was found by meaning.

## Proving there is no egress

`scripts/offline_proof.sh` in the core repository runs the whole proof on one connected machine: it builds and pulls, then starts the stack on a Docker network with no route out, checks that no container can reach the internet, stores three records and finds one by meaning, checks the archive holds them encrypted, deletes the database volume and checks the records and their vectors come back from the archive. By hand, on a host with no route out:

1. `curl -s http://localhost:8765/health` reports `healthy`, with `embedding.state` `ok`.
2. Store a record and find it by meaning (quickstart steps 10 and 11). A similarity result proves the local model answered.
3. `docker compose logs gateway local-embed` shows no failed outbound connection.

## Exchanging with other sites

An offline stack can still be peered with stacks it can reach on its own network; it exchanges only when connected. See [stacks in a mesh](stacks-in-a-mesh.md).
