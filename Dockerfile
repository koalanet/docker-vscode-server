FROM openanolis/anolisos:8.6

# 安装基础工具
RUN yum install -y wget curl vim git make telnet
# 安装开发工具
RUN yum groupinstall -y "Development Tools"
# 安装redis
RUN yum install -y redis

COPY ./docker-install.sh .
RUN ./docker-install.sh
RUN rm -f ./docker-install.sh

COPY ./docker-entrypoint.sh /usr/local/bin

# redis后台模式运行
RUN echo "daemonize yes" >> /etc/redis.conf
RUN echo "pidfile /var/run/redis.pid" >> /etc/redis.conf

# 部署code-server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh

# yum清除缓存
RUN yum clean all

RUN mkdir -p /code
WORKDIR /code

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD [ "code-server" ]