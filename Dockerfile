FROM openanolis/anolisos:8.6

# 安装基础工具
RUN yum install -y wget curl vim git make

# 部署code-server
RUN wget -O- https://aka.ms/install-vscode-server/setup.sh | sh

# yum清除缓存
RUN yum clean all
