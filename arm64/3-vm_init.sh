#!/bin/sh

sudo su -

PREBUILD=true
HADOOP_VERSION=2.7.3
HIVE_VERSION=2.1.1
HIVEMALL_REPOSITORY='https://github.com/amaya382/incubator-hivemall.git'
HIVEMALL_BRANCH='cross-compiling'
BASE_URL='https://www.apache.org/dyn/mirrors/mirrors.cgi?action=download&filename='

export JAVA_HOME='/usr/lib/jvm/java-8-openjdk-arm64'
export HADOOP_HOME='/usr/local/hadoop'
export HIVE_HOME='/usr/local/hive'
export HIVEMALL_PATH='/opt/hivemall'
export HADOOP_OPTS='-Dsystem:java.io.tmpdir=/tmp -Dsystem:user.name=root -Dderby.stream.error.file=/root/derby.log -Djava.library.path=${HADOOP_HOME}/lib'
export HADOOP_COMMON_LIB_NATIVE_DIR="${HADOOP_HOME}/lib/native"
export PATH="${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${PATH}"

set -eux && \
    apt update && \
    apt install -y --no-install-recommends openjdk-8-jdk git openssh-server maven g++ make && \
    \
    git clone -b ${HIVEMALL_BRANCH} ${HIVEMALL_REPOSITORY} ${HIVEMALL_PATH} && \
    mkdir -p ${HIVEMALL_PATH}/xgboost/src/main/resources/lib/linux-arm64 && \
    mv /home/ubuntu/libxgboost4j.so ${HIVEMALL_PATH}/xgboost/src/main/resources/lib/linux-arm64 && \
    \
    wget ${BASE_URL}hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -O - \
      | tar xz && \
    mv -f hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    sed -i -e 's!${JAVA_HOME}!'"${JAVA_HOME}!" ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    [ ! -e ~/.ssh/id_rsa ] && ssh-keygen -q -P '' -f ~/.ssh/id_rsa || : && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    [ ! -e ~/.ssh/config ] && echo 'host *\n  StrictHostKeyChecking no' > ~/.ssh/config || : &&
    cp -f ${HIVEMALL_PATH}/resources/docker/etc/hadoop/*.xml ${HADOOP_HOME}/etc/hadoop && \
    hdfs namenode -format && \
    \
    wget ${BASE_URL}hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz -O - \
      | tar xz && \
    mv -f apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} && \
    cat ${HIVE_HOME}/conf/hive-default.xml.template \
      | sed -e 's!databaseName=metastore_db!databaseName=/root/metastore_db!' \
      > ${HIVE_HOME}/conf/hive-site.xml && \
    \
    cd ${HIVEMALL_PATH} && \
    HIVEMALL_VERSION=`cat VERSION` && \
    \
    (if ${PREBUILD}; then \
      cd ${HIVEMALL_PATH} && bin/build.sh; \
    fi) && \
    \
    mkdir -p /root/bin /root/hivemall && \
    find ${HIVEMALL_PATH}/resources/docker/home/bin -mindepth 1 -maxdepth 1 \
      -exec sh -c 'f={} && ln -s $f /root/bin/${f##*/}' \; && \
    ln -s ${HIVEMALL_PATH}/resources/docker/home/.hiverc /root && \
    ln -s ${HIVEMALL_PATH}/resources/ddl/define-all.hive /root/hivemall/define-all.hive && \
    ln -s ${HIVEMALL_PATH}/target/hivemall-core-${HIVEMALL_VERSION}-with-dependencies.jar \
      /root/hivemall/hivemall-core-with-dependencies.jar

# Using ports: 8088 19888 50070
bin/init.sh

# If fail to start NameNode, run as below again
# export JAVA_HOME='/usr/lib/jvm/java-8-openjdk-arm64' && export HADOOP_HOME=/usr/local/hadoop && export HIVE_HOME=/usr/local/hive && export PATH=${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${PATH} && export HADOOP_OPTS='-Dsystem:java.io.tmpdir=/tmp -Dsystem:user.name=root -Dderby.stream.error.file=/root/derby.log -Djava.library.path=${HADOOP_HOME}/lib' && export HADOOP_COMMON_LIB_NATIVE_DIR=${HADOOP_HOME}/lib/native && ${HADOOP_HOME}/sbin/start-dfs.sh

# bin/prepare_iris.sh
# hive
