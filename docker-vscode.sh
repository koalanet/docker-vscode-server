#!/bin/sh

COMMAND=$1
COMMAND_ARGS=$2

ask_input() {
  read -r -p "$1 [y/N] " input
  case $input in 
    [yY][eE][sS]|[yY])
      docker compose down
      return 0
  esac

  return 1
}

# 清理数据
if [ "${COMMAND}" = "clean" ]; then
  docker ps -a

  if ask_input "是否卸载容器?"; then
    echo "正在卸载容器..."
    docker compose down
  fi

  if ask_input "是否清除用户数据?清理后将无法恢复"; then 
    echo "删除用户数据..."
    rm -f ./docker-compose.yml
    rm -fr ./data
  fi

  # 输出docker占用空间
  docker system df 

  if ask_input "是否清理Docker Build Cache?"; then 
    echo "清理Docker Build Cache..."
    docker builder prune
  fi

  exit
elif [ "${COMMAND}" = "network" ]; then
  docker network create --subnet=10.10.1.0/16 --gateway=10.10.1.1 --opt "com.docker.bridge.name"="bridge-dev" bridge-dev
  exit
elif [ "${COMMAND}" = "up" ]; then
  docker compose up -d
  exit
elif [ "${COMMAND}" = "down" ]; then
  docker compose down
  exit
elif [ "${COMMAND}" = "stop" ]; then
  docker compose stop
  exit
elif [ "${COMMAND}" = "start" ]; then
  docker compose start
  exit
elif [ "${COMMAND}" = "restart" ]; then
  docker compose restart
  exit
elif [ "${COMMAND}" = "build" ]; then
  docker build -t taodev/vscode-server:latest .
  exit
elif [ "${COMMAND}" = "install" ]; then

CURRENT_DIR=$(cd $(dirname $0); pwd)

# 名称
HOST_USER=$2

# 基础目录环境变量
HOST_ROOT=$CURRENT_DIR/data
HOME_PATH=$HOST_ROOT/home
APP_ROOT=$HOST_ROOT/app

# 开发工具环境变量
VSCODE_SERVER_PATH=$APP_ROOT/vscode-server
GOLANG_PATH=$APP_ROOT/go
NODE_PATH=$APP_ROOT/node

# 创建data目录
if [ ! -d "$HOST_ROOT" ]; then
  echo "mkdir -p $HOST_ROOT"
  mkdir -p $HOST_ROOT
fi

# 创建home目录
if [ ! -d "$HOME_PATH" ]; then
  echo "mkdir -p $HOME_PATH"
  mkdir -p $HOME_PATH
fi

# 创建code-server目录
if [ ! -d "$VSCODE_SERVER_PATH" ]; then
  echo "mkdir -p $VSCODE_SERVER_PATH"
  mkdir -p $VSCODE_SERVER_PATH
fi

# 安装golang
install_golang() {
  mkdir -p $GOLANG_PATH

  # 下载安装包
  wget https://golang.google.cn/dl/go1.19.2.linux-amd64.tar.gz
  tar -C $GOLANG_PATH -zxf ./go1.19.2.linux-amd64.tar.gz
  rm -f ./go1.19.2.linux-amd64.tar.gz
  mv $GOLANG_PATH/go $GOLANG_PATH/go1.19.2

  # 配置环境变量在docker中去执行"sh /host/install.sh"
}

if [ ! -d "$GOLANG_PATH" ]; then
  install_golang
fi

# 安装nodejs
install_node() {
  mkdir -p $NODE_PATH

  # 下载安装包
  wget https://nodejs.org/dist/v16.18.0/node-v16.18.0-linux-x64.tar.xz
  tar -C $NODE_PATH -xf ./node-v16.18.0-linux-x64.tar.xz
  rm -f ./node-v16.18.0-linux-x64.tar.xz
  mv $NODE_PATH/node-v16.18.0-linux-x64 $NODE_PATH/node-v16.18.0
  
  # 配置环境变量在docker中去执行"sh /host/install.sh"
}

if [ ! -d "$NODE_PATH" ]; then
  install_node
fi

# 生成docker-compose.yml
# mkdir -p ./docker
DOCKER_COMPOSE_FILE="./docker-compose.yml"
DOCKER_COMPOSE=$(cat <<- EOF
version: '1.0'

services:
  vscode-server:
    container_name: vscode-server-$HOST_USER
    hostname: dev-$HOST_USER
    image: taodev/vscode-server
    restart: always
    command: code-server serve-local --host 0.0.0.0 --port 80 --accept-server-license-terms --server-data-dir=/host/app/vscode-server --without-connection-token
    networks:
      - bridge-dev
    ports:
      - "127.0.0.1:11080:80"
      - "11000-11010:8000-8010"
      - "11100:9317"
    volumes:
      - $HOST_ROOT:/host
      - $HOME_PATH:/root
      - $GOLANG_PATH/go1.19.2:/usr/local/go
      - $NODE_PATH/node-v16.18.0:/usr/local/node

networks:
  bridge-dev:
    external: true
EOF
)

build_docker_compose() {
  echo "$DOCKER_COMPOSE" > $DOCKER_COMPOSE_FILE
}

if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
  build_docker_compose
fi

# 生成.bash_profile
BASH_PROFILE_FILE="$HOME_PATH/.bash_profile"
BASH_PROFILE=$(cat <<- EOF
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GOROOT=/usr/local/go
export GOPATH=/host/go
export PATH=\$PATH:/usr/local/go/bin:/host/go/bin:/usr/local/node/bin

EOF
)

build_bash_profile() {
  echo "$BASH_PROFILE" > $BASH_PROFILE_FILE
}

if [ ! -f "$BASH_PROFILE_FILE" ]; then
  build_bash_profile
fi

# 生成.bashrc
BASHRC_FILE="$HOME_PATH/.bashrc"
BASHRC=$(cat << EOF
# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi
EOF
)

build_bashrc() {
  echo "$BASHRC" > $BASHRC_FILE
}

if [ ! -f "$BASHRC_FILE" ]; then
  build_bashrc
fi

echo "安装完成"

exit 

# end of install
else
  echo "docker-vscode v1.0"
fi 