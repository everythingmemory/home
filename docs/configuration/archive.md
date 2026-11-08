# Archive

Where the archive is written, and the key that encrypts it.

| Setting | Engine default | Shipped | What it does |
|---|---|---|---|
| `ARCHIVE_MODE` | `disabled` | required; the template ships `local` | The one archive setting. `local`: the [archive](../durability/archive-and-restore.md) is the folder `ARCHIVE_DIR`. `s3`: an S3 bucket. `disabled`: no archive. Any other value stops the engine at start |
| `ARCHIVE_DIR` | — | required, in every mode; `./e.sh init` makes the folder and sets it | The absolute path of the host folder that holds the archive. It is bind-mounted into the engine and its workers at `/archive`, so it must exist before the first start. The shipped compose mounts it whatever the mode (compose cannot mount a folder conditionally), so a stack on `s3` or `disabled` still names an existing folder; nothing is written there |
| `ARCHIVE_PREFIX` | empty | empty | A folder (or, in a bucket, a name prefix) every object is written under, to share one archive between stacks |
| `ARCHIVE_KEY` | empty | required; `./e.sh init` generates it | The archive encryption key: 32 random bytes, base64-encoded — the one archive setting whose format is required. Object bodies are encrypted with AES-256-GCM |
| `ARCHIVE_READ_ONLY` | `false` | — | Restores from the archive and never writes to it |
| `ARCHIVE_BUCKET`, `ARCHIVE_ENDPOINT_URL`, `ARCHIVE_REGION`, `ARCHIVE_ACCESS_KEY`, `ARCHIVE_SECRET_KEY` | empty, empty, `nyc3`, empty, empty | empty, empty, `us-east-1`, empty, empty | The S3 bucket, with `ARCHIVE_MODE=s3`; see below |
| `RESTORE_FETCH_CONCURRENCY`, `RESTORE_FETCH_TIMEOUT_SECONDS` | `16`, `30` | — | How many archive objects a restore fetches at once, and how long one fetch may take |

## The folder

With `ARCHIVE_MODE=local`, as shipped, the engine writes the archive itself: one encrypted file per object, in the `ARCHIVE_DIR` folder. No other service runs for it.

- **An object's name is its path.** Each `/` in the name is a subfolder: `ARCHIVE_DIR/<ARCHIVE_PREFIX>/srs/<record>/<version>_<event>.json`, and likewise `cors/`, `pol/`, `spaces/`, `audit/`, `engine/` and `peers/`. `srs/` holds one folder per record and `spaces/<space>/` one file per record, so both grow large; a bare `ls` of them is slow.
- **A file appears whole or not at all.** The engine writes an object to a temporary file beside it, named `.<name>.tmp-<random>`, flushes it to disk, renames it onto the real name and flushes the folder. A write that fails (a full disk, say) removes its own temporary file. A crash can leave one behind; the engine never reads, lists or removes it. To clear them, stop the stack and run `find "$ARCHIVE_DIR" -type f -name '.*.tmp-*' -delete` (with `sudo` on Linux).
- **Nothing is deleted.** The engine writes and reads; it never removes an object.
- **A full disk stops the write.** Running out of space or inodes, or a permission fault, fails the write with the path. The object is written again by the next sync sweep.
- **On Linux the archive's files are root's.** The engine runs as root, so back the folder up with `sudo` (`sudo cp -a`, `sudo tar`). On macOS, Docker's file sharing gives them to you.
- **`ARCHIVE_DIR` outlives the stack.** It is a host folder, so `docker compose down -v` does not touch it.
- **A missing folder is refused, never created.** `docker compose up` refuses a path that does not exist, so a mistyped one never starts an empty archive. A relative path, or one with `.` or `..`, stops the engine at start, naming `ARCHIVE_DIR`.
- **On macOS**, the folder must sit under a folder Docker shares with its containers: `/Users`, `/Volumes` or `/private`.
- **Keep `ARCHIVE_KEY` apart from the archive**, in a password manager. A lost key is an unreadable archive.
- **The index is rebuilt from the archive.** The database is the index; the sync sweep restores it from the archive when a worker starts and every 5 minutes.
- **What a crash can't break, and what it can.** An object the engine has written survives a crash of the engine or a container. Surviving a power cut or a host crash is the host filesystem's guarantee, as for any file; behind Docker Desktop's or Colima's file sharing, whether a flush reaches the disk is the virtual machine's.

## An S3 bucket instead

Set `ARCHIVE_MODE=s3` and the archive is a bucket on any S3-compatible store (DigitalOcean Spaces, Amazon S3, MinIO). Set `ARCHIVE_BUCKET`, `ARCHIVE_ENDPOINT_URL`, `ARCHIVE_ACCESS_KEY`, `ARCHIVE_SECRET_KEY` and `ARCHIVE_REGION` to the store's, and restart. The bucket must exist: the engine does not create one. Nothing copies objects between the folder and a bucket.

## The mode is checked at start

The engine and every worker refuse to start, naming the settings, when:

- `ARCHIVE_MODE` is not `local`, `s3` or `disabled`;
- `ARCHIVE_MODE=local` or `disabled` and `ARCHIVE_BUCKET` or `ARCHIVE_ENDPOINT_URL` is set;
- `ARCHIVE_MODE=s3` and any of `ARCHIVE_BUCKET`, `ARCHIVE_ENDPOINT_URL`, `ARCHIVE_ACCESS_KEY` or `ARCHIVE_SECRET_KEY` is empty;
- `ARCHIVE_MODE=local` and the archive folder, `/archive` in the container, does not exist (the stack was started without its mount);
- `ARCHIVE_ENABLED` is set to any non-empty value: it is retired, and `ARCHIVE_MODE` says whether the archive is on.

The shipped compose requires `ARCHIVE_MODE` in `.env`: `docker compose up` refuses without it, naming it.
