#!/bin/bash

# https://github.com/hendrycks/natural-adv-examples?tab=readme-ov-file
# chmod u+x ./imagenet-o.sh
# ./imagenet-o.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-o
# ./imagenet-o.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-o --decompress

# Function to display usage
usage() {
  echo "Usage: $0 root_dir [--decompress]"
  exit 1
}

# Check if the first argument is provided
if [ -z "$1" ]; then
  echo "Error: root_dir is not specified."
  usage
fi

# Set ROOT_DIR from the first argument
ROOT_DIR=$1

# Check for --decompress flag
DECOMPRESS=false
if [ "$2" == "--decompress" ]; then
  DECOMPRESS=true
fi

# Create ROOT_DIR if it doesn't exist
if [ ! -d "$ROOT_DIR" ]; then
  mkdir -p "$ROOT_DIR"
  echo "Created directory: $ROOT_DIR"
fi

# Change to ROOT_DIR
cd "$ROOT_DIR" || { echo "Failed to change directory to $ROOT_DIR"; exit 1; }

# Download imagenet-o.tar
FILENAME=imagenet-o.tar
wget -c --quiet --show-progress https://people.eecs.berkeley.edu/~hendrycks/$FILENAME

echo "Download completed in $ROOT_DIR"

# Decompress the file if --decompress flag is set
if [ "$DECOMPRESS" = true ]; then
  echo "Extracting file..."
  tar -xf "$FILENAME"
  echo "Decompressed $FILENAME"
fi

# Compute SHA256 hash and rename the file
HASH=$(sha256sum imagenet-o.tar | awk '{print $1}')
HASH_PREFIX=${HASH:0:10}
NEW_FILENAME="imagenet-o-$HASH_PREFIX.tar"
mv imagenet-o.tar "$NEW_FILENAME"
echo "Renamed file to $NEW_FILENAME"

# Check if file size has changed before uploading
LOCAL_SIZE=$(stat -c%s "$NEW_FILENAME")
REMOTE_SIZE=$(aws s3api head-object --bucket visionlab-datasets --key imagenet-o/"$NEW_FILENAME" --profile wasabi-admin --query 'ContentLength' --output text 2>/dev/null)
echo "LOCAL_SIZE=$LOCAL_SIZE"
echo "REMOTE_SIZE=$REMOTE_SIZE"

if [ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]; then
  # Upload to Wasabi S3 bucket
  echo "Uploading to s3 bucket..."
  aws s3 cp "$NEW_FILENAME" s3://visionlab-datasets/imagenet-o/"$NEW_FILENAME" --profile wasabi-admin
  echo "File uploaded to s3://visionlab-datasets/imagenet-o/$NEW_FILENAME"
else
  echo "File size has not changed. Skipping upload."
fi
