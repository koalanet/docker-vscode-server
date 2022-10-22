#!/bin/sh

COMMAND=$1
COMMAND_ARGS=$2

CURRENT_DIR=$(cd $(dirname $0); pwd)

# 用户名称
VSCODE_USER=$2

# 基础目录环境变量
# 编排文件目录
COMPOSE_PATH=$CURRENT_DIR/compose
COMPOSE_FILE=$COMPOSE_PATH/$VSCODE_USER.yml

# 下载缓存目录
DOWN_PATH=$CURRENT_DIR/down

# 应用目录
APP_PATH=$CURRENT_DIR/app/$VSCODE_USER
# home目录(重要文件不要存在这个目录下)
HOME_PATH=$CURRENT_DIR/home/$VSCODE_USER
# 用户代码目录(记得周期性备份)
CODE_PATH=$CURRENT_DIR/code/$VSCODE_USER
# 应用数据目录(数据库相关文件存储目录，建议不要在redis里面存储重要文件)
DATA_PATH=$CURRENT_DIR/data/$VSCODE_USER

ask_input() {
  read -r -p "$1 [y/N] " input
  case $input in 
    [yY][eE][sS]|[yY])
      return 0
  esac

  return 1
}

# 清理数据
if [ "${COMMAND}" = "clean" ]; then
  docker ps -a

  if ask_input "是否卸载容器?"; then
    echo "正在卸载容器..."
    docker compose --file=$COMPOSE_FILE down
  fi

  if ask_input "是否删除docker-compose-$VSCODE_USER.yml"; then 
    rm -f $COMPOSE_FILE
  fi

  if ask_input "是否删除$APP_PATH"; then 
    rm -fr $APP_PATH
  fi

  if ask_input "是否删除$HOME_PATH"; then 
    rm -fr $HOME_PATH
  fi

  if ask_input "是否删除$CODE_PATH"; then 
    rm -fr $CODE_PATH
  fi

  if ask_input "是否删除$DATA_PATH"; then 
    rm -fr $DATA_PATH
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
elif [ "${COMMAND}" = "down" ]; then
  docker compose --file=$COMPOSE_FILE down
  exit
elif [ "${COMMAND}" = "stop" ]; then
  docker compose --file=$COMPOSE_FILE stop
  exit
elif [ "${COMMAND}" = "start" ]; then
  docker compose --file=$COMPOSE_FILE start
  exit
elif [ "${COMMAND}" = "restart" ]; then
  docker compose --file=$COMPOSE_FILE restart
  exit
elif [ "${COMMAND}" = "build" ]; then
  docker build -t taodev/vscode-server:latest .
  exit
elif [ "${COMMAND}" = "up" ]; then

if [ ! -d "$COMPOSE_PATH" ]; then
  mkdir -p $COMPOSE_PATH echo $COMPOSE_PATH
fi

if [ ! -d "$DOWN_PATH" ]; then
  mkdir -p $DOWN_PATH echo $DOWN_PATH
fi

# 用户目录是否存在
if [ ! -d "$APP_PATH" ]; then
  echo "初始化用户目录"

  # 创建app目录
  mkdir -p $APP_PATH && echo $APP_PATH
  # 创建home目录
  mkdir -p $HOME_PATH && echo $HOME_PATH
  # 创建代码目录
  mkdir -p $CODE_PATH && echo $CODE_PATH
  # 创建app数据目录
  mkdir -p $DATA_PATH && echo $DATA_PATH

  # 创建vscode-server目录
  mkdir -p $APP_PATH/vscode-server && echo $APP_PATH/vscode-server
  # 创建redis数据目录
  mkdir -p $DATA_PATH/redis && echo $DATA_PATH/redis

  # 安装nodejs
  if [ ! -f "$DOWN_PATH/node-v16.18.0-linux-x64.tar.xz" ]; then
    curl -o down/node-v16.18.0-linux-x64.tar.xz -O https://nodejs.org/dist/v16.18.0/node-v16.18.0-linux-x64.tar.xz
  fi 

  tar -xf $DOWN_PATH/node-v16.18.0-linux-x64.tar.xz -C $APP_PATH
  mv $APP_PATH/node-v16.18.0-linux-x64 $APP_PATH/node
fi

# 生成docker-compose.yml
DOCKER_COMPOSE_FILE=$COMPOSE_FILE
DOCKER_COMPOSE=$(cat <<- EOF
version: '1.0'

services:
  vscode-server:
    container_name: dev-$VSCODE_USER
    hostname: dev-$VSCODE_USER
    image: taodev/vscode-server
    restart: always
    networks:
      - bridge-dev
    ports:
      - "127.0.0.1:11080:80"
      - "11000-11010:8000-8010"
      - "11100:9317"
    volumes:
      - $APP_PATH:/app
      - $HOME_PATH:/root
      - $CODE_PATH:/code
      - $DATA_PATH:/data

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
export GOPATH=/code
export PATH=\$PATH:/code/bin:/app/node/bin:/root/bin

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

# 安装并容器
docker compose --file=$COMPOSE_FILE up

exit 

# end of install
else
  echo "docker-vscode v1.0"
fi 