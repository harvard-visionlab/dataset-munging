#!/bin/bash

# https://github.com/HaohanWang/ImageNet-Sketch
# chmod u+x ./imagenet-sketch.sh
# ./imagenet-sketch.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-sketch
# ./imagenet-sketch.sh /home/jovyan/work/DataExactitudeBigData/DataSets/ImageSets/imagenet-sketch --decompress

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

# args
FILENAME=ImageNet-Sketch.zip
GOOGLE_DRIVE_FILE_ID=1Mj0i5HBthqH1p_yeXzsg22gZduvgoNeA
BUCKET=visionlab-datasets
BUCKET_FOLDER=imagenet-sketch

# Split the filename into stem and extension
STEM="${FILENAME%.*}"
if [[ "$FILENAME" == *.tar.gz ]]; then
  EXT="tar.gz"
else
  EXT="${FILENAME##*.}"
fi

# Download
if [ ! -f "$FILENAME" ]; then
  gdown https://drive.google.com/uc?id="$GOOGLE_DRIVE_FILE_ID" -O "$FILENAME"
else
  echo "File $FILENAME already exists. Skipping download."
fi

echo "Download completed in $ROOT_DIR"

# Decompress the file if --decompress flag is set
if [ "$DECOMPRESS" = true ]; then
  echo "Extracting file..."
  if [ "$EXT" = "zip" ]; then
    # unzip -o $FILENAME -d $ROOT_DIR | pv -l >/dev/null
    n_files=$(unzip -l "$FILENAME" | grep -c '.JPEG')
    unzip -o "$FILENAME" -d "$ROOT_DIR" | pv -l -s "$n_files" > /dev/null
    echo "Decompressed zip file $FILENAME"
  elif [ "$EXT" = "tar" ] || [ "$EXT" = "tar.gz" ]; then
    pv "$FILENAME" | tar --checkpoint=1000 --checkpoint-action=dot -xzf - -C "$ROOT_DIR"
    echo "Decompressed tar file $FILENAME"
  else
    echo "Unsupported file extension for decompression: $EXT"
  fi
fi

# Compute SHA256 hash and rename the file
HASH=$(sha256sum $FILENAME | awk '{print $1}')
HASH_PREFIX=${HASH:0:10}
NEW_FILENAME="$STEM-$HASH_PREFIX.$EXT"
mv $FILENAME "$NEW_FILENAME"
echo "Renamed file to $NEW_FILENAME"

# Check if file size has changed before uploading
LOCAL_SIZE=$(stat -c%s "$NEW_FILENAME")
REMOTE_SIZE=$(aws s3api head-object --bucket $BUCKET --key imagenet-sketch/"$NEW_FILENAME" --profile wasabi-admin --query 'ContentLength' --output text 2>/dev/null)
echo "LOCAL_SIZE=$LOCAL_SIZE"
echo "REMOTE_SIZE=$REMOTE_SIZE"

if [ "$LOCAL_SIZE" != "$REMOTE_SIZE" ]; then
  # Upload to Wasabi S3 bucket
  echo "Uploading to s3 bucket..."
  aws s3 cp "$NEW_FILENAME" s3://"$BUCKET"/"$BUCKET_FOLDER"/"$NEW_FILENAME" --profile wasabi-admin
  echo "File uploaded to s3://$BUCKET/$BUCKET_FOLDER/$NEW_FILENAME"
else
  echo "File size has not changed. Skipping upload."
fi
