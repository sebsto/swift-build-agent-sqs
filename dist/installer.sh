#!/bin/sh

HOME=/Users/ec2-user
AGENT_BINARY=SQSBuildAgent
AGENT_STARTUP_FILE=com.amazon.build.mac.agent.plist
AGENT_PACKAGE=https://download.stormacq.com/aws/mac/build/$AGENT_BINARY.zip

LOG_DIR=/Users/ec2-user/log

echo "Downloading build agent"
curl -s -o $HOME/$AGENT_BINARY.zip $AGENT_PACKAGE

pushd $HOME
echo "Installing agent"
unzip -o -q $AGENT_BINARY.zip
chown ec2-user:staff $AGENT_BINARY
cp $AGENT_STARTUP_FILE /Library/LaunchDaemons/
chown root:wheel /Library/LaunchDaemons/$AGENT_STARTUP_FILE
mkdir -p $LOG_DIR
chown ec2-user:staff $LOG_DIR
chmod 700 $LOG_DIR
echo "Starting agent"
/bin/launchctl load /Library/LaunchDaemons/$AGENT_STARTUP_FILE
popd