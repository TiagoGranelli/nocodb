# Deploy NocoDB on Cloud Run

## Prerequisites

- Docker with buildx enabled
- `gcloud` CLI authenticated
- `pnpm` and `rsync` installed

## First-time setup

This will setup gcloud project.

```bash
make setup
```

## Deploy

Builds the Docker image, pushes it to GCR, and deploys to Cloud Run.

Equivalent to running `make build push run` individually.

```bash
make deploy
```

## Configuration

All variables can be overridden:

```bash
make deploy IMAGE_TAG=nocodb-v2 GCR_PROJECT=my-gcp-project REGION=us-central1
```

| Variable | Default | Description |
|----------|---------|-------------|
| `IMAGE_TAG` | `nocodb-local` | Local Docker image name |
| `GCR_PROJECT` | `propelio-development` | GCP project ID |
| `PLATFORM` | `linux/amd64` | Target build platform |
| `SERVICE_NAME` | `nocodb` | Cloud Run service name |
| `REGION` | `europe-west1` | Cloud Run region |
| `CLOUDSQL_INST` | `propelio-development:europe-west1:propelio-development-dwh` | Cloud SQL instance connection |

## Logs

Build logs are written to `build-local-docker-image-cross.log`.

