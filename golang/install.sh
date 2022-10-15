#!/bin/sh

# 安装基础工具
yum install -y wget vim git make
# yum groupinstall -y "Development Tools"
yum clean all

# 解压golang
wget https://golang.google.cn/dl/go1.19.2.linux-amd64.tar.gz
tar -C /usr/local -zxf ./go1.19.2.linux-amd64.tar.gz
rm -f ./go1.19.2.linux-amd64.tar.gz

# 解压nodejs
# tar -C /usr/local -xf ./node-v16.17.1-linux-x64.tar.xz
# mv /usr/local/node-v16.17.1-linux-x64 /usr/local/node
# rm -f ./node-v16.17.1-linux-x64.tar.xz

# 配置环境变量
echo "export GO111MODULE=on" >> /etc/profile
echo "export GOPROXY=https://goproxy.cn,direct" >> /etc/profile
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export GOPATH=/root/code" >> /etc/profile
source /etc/profile

# echo "export PATH=$PATH:/usr/local/go/bin:/code/bin:/usr/local/node/bin" >> /etc/profile
echo "export PATH=$PATH:$GOROOT/bin:$GOPATH/bin" >> /etc/profile

source /etc/profile
