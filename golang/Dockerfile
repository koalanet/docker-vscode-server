FROM openanolis/anolisos:8.6

WORKDIR /root

COPY ./install.sh ./

# 执行安装命令
RUN /bin/sh ./install.sh
RUN rm -f ./install.sh

# 部署code-server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh