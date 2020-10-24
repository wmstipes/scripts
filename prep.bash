#!/bin/bash
#############################################################################
# This is to prep the new system for CIS testing

yum install unzip -y

# Install AWS CLI tools
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm awscliv2.zip

# Make the needed directories
mkdir outputFiles/
mkdir inputFiles/

# Download the required files
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/fileSystems.txt ./inputFiles/fileSystems
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/yumInstall.txt ./inputFiles/yumInstall
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/yumRemove.txt ./inputFiles/yumRemove
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/protocols.txt ./inputFiles/protocols
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/rsyslogRules.txt ./inputFiles/rsyslogRules
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/rsyslogConfig.txt ./inputFiles/rsyslogConfig
/usr/local/aws-cli/v2/2.0.3/bin/aws s3 cp s3://stipes-test/sshd_config.txt ./inputFiles/sshd_config

# Change permissions on the files
chmod 755 ./inputFiles/fileSystems
chmod 755 ./inputFiles/yumInstall
chmod 755 ./inputFiles/yumRemove
chmod 755 ./inputFiles/protocols
chmod 755 ./inputFiles/rsyslogRules
chmod 755 ./inputFiles/rsyslogConfig
chmod 755 ./inputFiles/sshd_config

# Cleanup after complted.
rm ./awscliv2.zip
rm -rf ./aws/