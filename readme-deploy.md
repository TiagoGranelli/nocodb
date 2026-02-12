# Deploy NocoDB on Cloud Run

## Prerequisites

- Docker with buildx enabled
- `gcloud` CLI authenticated (`gcloud auth configure-docker`)
- `pnpm` installed
- `rsync` installed

## Quick deploy

```bash
make deploy
```

This builds the image for `linux/amd64`, tags it as `gcr.io/propelio-development/nocodb-local`, and pushes it to GCR.

## Step by step

```bash
# 1. Build the Docker image for linux/amd64
make build

# 2. Tag and push to GCR
make push
```

## Custom configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE_TAG` | `nocodb-local` | Local Docker image name |
| `GCR_PROJECT` | `propelio-development` | GCP project ID |
| `PLATFORM` | `linux/amd64` | Target platform |

```bash
make deploy IMAGE_TAG=nocodb-v2 GCR_PROJECT=my-gcp-project
```

## Deploy on Cloud Run

After pushing, deploy via `gcloud`:

```bash
gcloud run deploy nocodb \
  --image gcr.io/propelio-development/nocodb-local \
  --platform managed \
  --region europe-west1 \
  --port 8080 \
  --allow-unauthenticated
```

## Logs

Build logs are written to `build-local-docker-image-cross.log` at the repo root.
