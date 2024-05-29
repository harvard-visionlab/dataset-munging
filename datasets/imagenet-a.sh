#!/bin/bash

# https://github.com/hendrycks/natural-adv-examples?tab=readme-ov-file
# chmod u+x ./imagenet-a.sh
# ./imagenet-a.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-a
# ./imagenet-a.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-a --decompress

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

# Download imagenet-a.tar
wget -c --quiet --show-progress https://people.eecs.berkeley.edu/~hendrycks/imagenet-a.tar

echo "Download completed in $ROOT_DIR"

# Decompress the imagenet-a.tar file
# tar -xf imagenet-a.tar
# echo "Extraction completed in $ROOT_DIR"

# Compute SHA256 hash and rename the file
HASH=$(sha256sum imagenet-a.tar | awk '{print $1}')
HASH_PREFIX=${HASH:0:10}
NEW_FILENAME="imagenet-a-$HASH_PREFIX.tar"
mv imagenet-a.tar "$NEW_FILENAME"
echo "Renamed file to $NEW_FILENAME"

# Upload to Wasabi S3 bucket
echo "Uploading to s3 bucket..."
aws s3 cp "$NEW_FILENAME" s3://visionlab-datasets/imagenet-a/"$NEW_FILENAME" --profile wasabi-admin

echo "File uploaded to s3://visionlab-datasets/imagenet-a/$NEW_FILENAME"

