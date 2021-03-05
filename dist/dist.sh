#!/bin/sh

echo "Building release binary"
(cd .. ; swift build -c release)
AGENT_BINARY=SQSBuildAgent
AGENT_STARTUP_FILE=./com.amazon.build.mac.agent.plist
AGENT_INSTALLER=installer.sh
RELEASE=../.build/release/$AGENT_BINARY

S3_DIST=s3://download.stormacq.com/aws/mac/build
S3_PROFILE=seb


if [ -f $AGENT_BINARY.zip ]; then
    echo "Cleaning"
    rm $AGENT_BINARY.zip
fi

echo "Zipping distribution files"
zip -q -j $AGENT_BINARY.zip $RELEASE $AGENT_STARTUP_FILE $AGENT_INSTALLER

echo "Uploading distribution file to S3"
aws --profile $S3_PROFILE s3 cp $AGENT_BINARY.zip $S3_DIST/$AGENT_BINARY.zip
aws --profile $S3_PROFILE s3 cp installer.sh $S3_DIST/installer.sh