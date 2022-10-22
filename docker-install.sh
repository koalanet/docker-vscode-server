#!/bin/sh

# 安装golang 
wget https://golang.google.cn/dl/go1.19.2.linux-amd64.tar.gz
tar -C /usr/local -zxf ./go1.19.2.linux-amd64.tar.gz
rm -f ./go1.19.2.linux-amd64.tar.gz

# 设置环境变量
echo "export GO111MODULE=on" >> /etc/profile
echo "export GOPROXY=https://goproxy.cn,direct" >> /etc/profile
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
