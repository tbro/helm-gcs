#!/bin/bash
REPO=$4
STORAGE_HOST=https://storage.googleapis.com

if [ -z ${GCLOUD_OAUTH_TOKEN+x} ]; then
    echo "please set GCLOUD_OAUTH_TOKEN in your environment"
    exit 1
fi

AUTH_STRING="Authorization: Bearer ${GCLOUD_OAUTH_TOKEN}"

PROTO="$(echo $4 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
BUCKET="$(echo ${4/$PROTO/})"

case "$PROTO" in
    "https://") curl -s -H "${AUTH_STRING}" "${REPO}";;
    "gs://") curl -s -H "${AUTH_STRING}" "${STORAGE_HOST}/${BUCKET}";;
    *) echo 'protocol error' && exit 1;;
esac

exit 0
