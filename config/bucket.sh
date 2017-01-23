#!/usr/bin/env bash

# Create the bucket for blobs and setup public read access
BUCKET=ansible-boshrelease

s3cmd mb "s3://${BUCKET}"
s3cmd setacl "s3://${BUCKET}"  --acl-public --recursive
