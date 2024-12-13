# AWS terraform sandbox

This is a sandbox repository I use for trying stuff out on AWS with terraform.

## EC2 instance connect

### Build ec2-instance-connect package

To build a Debian package of ec2-instance-connect:

1. Start a Debian instance
2. Install `unzip` and `devscripts`:
   ```bash
   sudo apt-get update
   sudo apt-get install -y unzip devscripts
   ```
3. Download a snapshot of the `aws/ec2-instance-connect-config` repository.
   ```bash
   wget https://github.com/aws/aws-ec2-instance-connect-config/archive/refs/heads/master.zip
   ```
4. Extract the sources and build the package
   ```bash
   unzip master
   cd aws-ec2-instance-connect-config-master
   make deb
   ```
5. Copy the created `.deb` package from the instance.

### Install package on an instance

To install the package on an instance (example):

```
sudo dpkg -i ec2-instance-connect_1.1.19_all.deb
```

### Connect to an instance

With aws CLI (example):

```bash
aws ec2-instance-connect ssh \
    --instance-id i-0a8ffd81a653cf0e6 \
    --os-user admin
```

With SSH, using a ProxyCommand (example):

```bash
ssh admin@i-0a8ffd81a653cf0e6 \
    -o ProxyCommand="aws ec2-instance-connect open-tunnel --instance-id %h"
```
