FROM bitnami/minideb

WORKDIR /root/

##修改镜像时区 
ENV TZ=Asia/Shanghai

ENV DBIP 127.0.0.1
ENV DBPort 3306
ENV DBUser root
ENV DBPassword password

##安装
RUN install_packages build-essential cmake wget mariadb-client libmariadbclient-dev libmariadbclient18 unzip iproute flex bison libncurses5-dev zlib1g-dev ca-certificates vim rsync locales \
	&& echo "UTF-8 zh_CN zh_CN.UTF-8" >> /etc/locale.gen && locale-gen && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
	&& localedef -c -f UTF-8 -i zh_CN zh_CN.UTF-8 \
	&& wget -c -t 0 https://github.com/Tencent/Tars/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv Tars-master Tars && rm -f /root/master.zip \
	&& mkdir -p /usr/local/mysql/lib && ln -s /usr/include/mysql /usr/local/mysql/include \
	&& ln -s /usr/lib/x86_64-linux-gnu/libmariadbclient.so.*.*.* /usr/local/mysql/lib/libmysqlclient.a \
	&& cd /root/Tars/cpp/thirdparty && wget -c -t 0 https://github.com/Tencent/rapidjson/archive/master.zip -O master.zip \
	&& unzip -a master.zip && mv rapidjson-master rapidjson && rm -f master.zip \
	&& mkdir -p /data && chmod u+x /root/Tars/cpp/build/build.sh \
	&& cd /root/Tars/cpp/build/ && ./build.sh all \
	&& ./build.sh install \
	&& cd /root/Tars/cpp/build/ && make framework-tar \
	&& mkdir -p /usr/local/app/tars/ && cp /root/Tars/cpp/build/framework.tgz /usr/local/app/tars/ \
	&& cd /usr/local/app/tars/ && tar xzfv framework.tgz && rm -rf framework.tgz \
	&& mkdir -p /usr/local/app/patchs/tars.upload \
	&& mkdir -p /root/init && cd /root/init/ \
	&& wget -c -t 0 --header "Cookie: oraclelicense=accept" --no-check-certificate http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz \
	&& tar zxf /root/init/jdk-8u131-linux-x64.tar.gz && rm -rf /root/init/jdk-8u131-linux-x64.tar.gz \
	&& mkdir /usr/java && mv /root/init/jdk1.8.0_131 /usr/java \
	&& echo "export JAVA_HOME=/usr/java/jdk1.8.0_131" >> /etc/profile \
	&& echo "CLASSPATH=\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar" >> /etc/profile \
	&& echo "PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile \
	&& echo "export PATH JAVA_HOME CLASSPATH" >> /etc/profile \
	&& cd /usr/local/ && wget -c -t 0 https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz \
	&& tar zxvf apache-maven-3.5.3-bin.tar.gz && echo "export MAVEN_HOME=/usr/local/apache-maven-3.5.3/" >> /etc/profile \
	&& echo "export PATH=\$PATH:\$MAVEN_HOME/bin" >> /etc/profile && . /etc/profile && mvn -v \
	&& rm -rf apache-maven-3.5.3-bin.tar.gz  \
	&& . /etc/profile && cd /root/Tars/java && mvn clean install && mvn clean install -f core/client.pom.xml && mvn clean install -f core/server.pom.xml \
	&& rm -rf /root/Tars \
	&& apt-get -y autoremove

ENV JAVA_HOME /usr/java/jdk1.8.0_131

ENV MAVEN_HOME /usr/local/apache-maven-3.5.3

# 是否将Tars系统进程的data目录挂载到外部存储，缺省为false以支持windows下使用
ENV MOUNT_DATA false

# 网络接口名称，如果运行时使用 --net=host，宿主机网卡接口可能不叫 eth0
ENV INET_NAME eth0

# master节点IP或主机名（如果--link了maser节点），用于注册node到master
ENV MASTER master

# 中文字符集支持
ENV LC_ALL "zh_CN.UTF-8"

VOLUME ["/data"]

##拷贝资源
COPY install.sh /root/init/
COPY entrypoint.sh /sbin/

ADD https://s3.amazonaws.com/download.fpcomplete.com/pid1/pid1-0.1.0-amd64 /sbin/pid1
RUN chmod 755 /sbin/pid1
ENTRYPOINT [ "/sbin/pid1" ]
CMD bash -c '/sbin/entrypoint.sh start'
