#!/usr/bin/env bash

declare -g AWS_S3_BUCKET="sandbox.aws.kosztadani.me"
declare -g INSTANCE_CONNECT_PACKAGE="ec2-instance-connect/ec2-instance-connect_1.1.19_all.deb"

aws s3 cp \
    "s3://${AWS_S3_BUCKET}/${INSTANCE_CONNECT_PACKAGE}" \
    /tmp/ec2-instance-connect.deb

dpkg -i /tmp/ec2-instance-connect.deb