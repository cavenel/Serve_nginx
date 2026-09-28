# Serve_nginx

A minimal static file server for [SciLifeLab Serve](https://serve.scilifelab.se/)
that exposes a folder of data to the browser with:

- **HTTP Range requests** (`206 Partial Content`, `Accept-Ranges`, `Content-Range`), so
  viewers that read files in chunks (OME-Zarr, OME-TIFF, COG, tiled pyramids, ...) work.
- **CORS enabled** for any origin, including the `Range` preflight and the exposed
  `Content-Range` / `Content-Length` headers that browser JavaScript needs to read.

Typical use: host image and table data on Serve and open it from
[TissUUmaps](https://tissuumaps.scilifelab.se/) or any other web viewer.

It is plain nginx in a container that follows the Serve rules for custom apps:
non-root user with UID 1000, startup script in `WORKDIR`, port 8080.

## Repository layout

```
Dockerfile                                 nginx:alpine image, runs as UID 1000
nginx.conf                                 Range + CORS configuration
start-script.sh                            startup script required by Serve
data/                                      files baked into the image (optional)
.github/workflows/docker-image-ghcr.yml    builds, tests and pushes the image to GHCR
```

## Deploy on Serve

### 1. Build the image with GitHub Actions

Every push to `main` builds the image, checks that Range and CORS work, and pushes it to
GitHub Container Registry with a unique tag. You can also start it manually from the
**Actions** tab (`Publish container image` → `Run workflow`).

After the first successful run:

1. Open **Packages** on the right-hand side of the repository page and click the package.
2. Under **Package settings**, set the visibility to **Public**. Serve can only pull public
   images.
3. Copy the image reference from the run summary. It looks like
   `ghcr.io/tissuumaps/serve_nginx:20260928-120000-abc1234-1-1`.

Serve does not re-pull an image whose tag it has already deployed, so always use the new
unique tag when you update the app. Never use `latest`.

### 2. Create the app

1. Log in to Serve and open or create a project.
2. On the **Custom app** card, click **Create** and fill in:
   - **Image**: the reference you copied above
   - **Port**: `8080`
   - **Permission**: `Link` while testing, `Public` when done
   - **Source code URL**: this repository
3. Wait a few minutes. Your data is then available at
   `https://<subdomain>.serve.scilifelab.se/<path-to-file>`.

### 3. Add your data

There are two options.

**Small, fixed datasets (a few hundred MB at most)**: put the files in `data/` before
pushing. They are copied into the image and served from the root of the app URL.

**Large or changing datasets**: leave `data/` empty and use the project volume.

1. In the Serve project, go to **Settings → Storage** and add the mount path
   `/home/serve/data`.
2. In the app form, select that mount path in the **Storage** field.
3. Upload your files to the project storage, for example from a notebook app in the same
   project (see the [Serve file management docs](https://serve.scilifelab.se/docs/files/)).

Mounting the volume at `/home/serve/data` hides anything baked into the image at that
path.

Storage auto-extends only up to 5 GB. For larger datasets contact the Serve team
(serve@scilifelab.se). Data hosted on Serve must be public and must not contain sensitive
information.

## Test locally

```bash
docker build --platform linux/amd64 -t serve_nginx:dev .
docker run --rm -p 8080:8080 -v "$PWD/data:/home/serve/data" serve_nginx:dev
```

```bash
# Expect "206 Partial Content", Content-Range and Access-Control-Allow-Origin
curl -s -D - -o /dev/null -H "Origin: https://example.org" -H "Range: bytes=0-99" \
  http://localhost:8080/README.txt

# Preflight: expect 204 with the Access-Control-* headers
curl -s -D - -o /dev/null -X OPTIONS \
  -H "Origin: https://example.org" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: range" \
  http://localhost:8080/README.txt
```

Run the same commands against `https://<subdomain>.serve.scilifelab.se/...` after
deploying to confirm that Serve's ingress keeps the `206` responses and the CORS headers
intact.

## Configuration notes

- Directory listings are on (`autoindex on` in `nginx.conf`). Remove that line to hide
  the file tree; files stay reachable by URL.
- `gzip` is off on purpose: nginx does not honour Range requests on compressed responses.
- `/healthz` returns `200 ok` and is used by the workflow smoke test and the Docker
  `HEALTHCHECK`.
- Access logging is off. Serve logs are meant for debugging, not user tracking.
