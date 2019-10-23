#!/bin/bash -e

if [ -z ${GCLOUD_OAUTH_TOKEN+x} ]; then
    echo "please set GCLOUD_OAUTH_TOKEN in your environment"
    exit 1
fi

function usage() {
  if [[ ! -z "$1" ]]; then
    printf "$1\n\n"
  fi
  cat <<'  EOF'
  Helm plugin for using Google Cloud Storage as a private chart repository

  To begin working with helm-gcs plugin, authenticate gcloud

    $ gcloud auth login

  Usage:
    helm gcs init [BUCKET_URL]
    helm gcs push [CHART_FILE] [BUCKET_URL]

  Available Commands:
    init    Initialize an existing Cloud Storage Bucket to a Helm repo
    push    Upload the chart to your bucket

  Example:

    $ helm gcs init gs://my-unique-helm-repo-bucket-name
    $ helm gcs push my-chart-0.1.0.tgz gs://my-unique-helm-repo-bucket-name

  EOF
}

COMMAND=$1
STORAGE_HOST=https://storage.googleapis.com
AUTH_STRING="Authorization: Bearer ${GCLOUD_OAUTH_TOKEN}"

case $COMMAND in
init)
  PROTO="$(echo $2 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  BUCKET="$(echo ${2/$PROTO/})"
  if [[ -z "$2" ]]; then
    usage "Error: Please provide a bucket name"
    exit 1
  else
      curl -s --upload-file ${HELM_PLUGIN_DIR}/etc/index.yaml \
           -H "${AUTH_STRING}" \
           "${STORAGE_HOST}/${BUCKET}/index.yaml"

    echo "Repository initialized..."
    exit 0
  fi
  ;;
push)
  if [[ -z "$2" ]] || [[ -z "$3" ]]; then
    usage "Error: Please provide chart file and/or bucket URL in the format gs://BUCKET"
    exit 1
  fi
  CHART_PATH=$2
  PROTO="$(echo $3 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  BUCKET="$(echo ${3/$PROTO/})"
  TMP_DIR=$(mktemp -d)
  TMP_REPO=$TMP_DIR/repo
  OLD_INDEX=$TMP_DIR/old-index.yaml

  curl -s -o ${OLD_INDEX} -H "${AUTH_STRING}" \
       "${STORAGE_HOST}/${BUCKET}/index.yaml"

  mkdir $TMP_REPO
  cp $CHART_PATH $TMP_REPO
  helm repo index --merge $OLD_INDEX --url $STORAGE_HOST/$BUCKET $TMP_REPO

  curl -s --upload-file "${TMP_REPO}/index.yaml" \
       -H "${AUTH_STRING}" \
       "${STORAGE_HOST}/${BUCKET}/"

  curl -s --upload-file "$TMP_REPO/$(basename $CHART_PATH)" \
       -H "${AUTH_STRING}" \
       "${STORAGE_HOST}/${BUCKET}/"

  echo "Repository initialized..."
  ;;
*)
  usage
  ;;
esac
