#!/bin/bash
export JAVA_HOME=/usr/local/java
export HADOOP_PREFIX=/usr/local/hadoop
JAVA_ARCHIVE=jdk-7u60-linux-x64.gz
HADOOP_DIRNAME=hadoop-2.6.0
HADOOP_ARCHIVE=$HADOOP_DIRNAME.tar.gz
SPARK_DIRNAME=spark-1.2.1-bin-hadoop2.4
SPARK_ARCHIVE=$SPARK_DIRNAME.tgz
HADOOP_MIRROR_DOWNLOAD=http://psg.mtu.edu/pub/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
SPARK_DOWNLOAD=http://archive.apache.org/dist/spark/spark-1.2.1/spark-1.2.1-bin-hadoop2.4.tgz
	
function fileExists {
	FILE=/vagrant/resources/$1
	if [ -e $FILE ]
	then
		return 0
	else
		return 1
	fi
}

function disableFirewall {
	echo "disabling firewall"
	service iptables save
	service iptables stop
	chkconfig iptables off
}

function installHostsFile {
    echo "installing /etc/hosts"
    cp /vagrant/resources/hosts /etc/hosts
}

function installLocalJava {
	echo "installing oracle jdk"
	FILE=/vagrant/resources/$JAVA_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteJava {
	echo "install open jdk"
	yum install -y java-1.7.0-openjdk.x86_64
}

function installLocalHadoop {
	echo "install hadoop from local file"
	FILE=/vagrant/resources/$HADOOP_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteHadoop {
	echo "install hadoop from remote file"
	curl -o /home/vagrant/$HADOOP_ARCHIVE -O -L $HADOOP_MIRROR_DOWNLOAD
	tar -xzf /home/vagrant/$HADOOP_ARCHIVE -C /usr/local
}

function installLocalSpark {
	echo "install spark from local file"
	FILE=/vagrant/resources/$SPARK_ARCHIVE
	tar -xzf $FILE -C /usr/local
}

function installRemoteSpark {
	echo "install spark from remote file"
	curl -o /home/vagrant/$SPARK_ARCHIVE -O -L $SPARK_DOWNLOAD
	tar -xzf /home/vagrant/$SPARK_ARCHIVE -C /usr/local
}

function setupSpark {
	echo "setting up spark"
	ln -s /usr/local/$SPARK_DIRNAME /usr/local/spark
}

function setupSparkThriftService {
	echo "setting up spark sql thrift service"
	cp -f /vagrant/resources/sparkthrift /etc/init.d/sparkthrift
	chmod 777 /etc/init.d/sparkthrift
	chkconfig --level 2345 sparkthrift on
}

function startSparkThriftService {
	echo "starting spark sql thrift service"
	service sparkthrift start
}

function setupJava {
	echo "setting up java"
	if fileExists $JAVA_ARCHIVE; then
		ln -s /usr/local/jdk1.7.0_51 /usr/local/java
	else
		ln -s /usr/lib/jvm/jre /usr/local/java
	fi
}

function setupHadoop {
	echo "creating hadoop directories"
	mkdir /tmp/hadoop-namenode
	mkdir /tmp/hadoop-logs
	mkdir /tmp/hadoop-datanode
	ln -s /usr/local/$HADOOP_DIRNAME /usr/local/hadoop
	echo "copying over hadoop configuration files"
	cp -f /vagrant/resources/core-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hdfs-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/mapred-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-site.xml /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/slaves /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/hadoop-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-env.sh /usr/local/hadoop/etc/hadoop
	cp -f /vagrant/resources/yarn-daemon.sh /usr/local/hadoop/sbin
	cp -f /vagrant/resources/mr-jobhistory-daemon.sh /usr/local/hadoop/sbin
	echo "modifying permissions on local file system"
	chown -fR vagrant /tmp/hadoop-namenode
    chown -fR vagrant /tmp/hadoop-logs
    chown -fR vagrant /tmp/hadoop-datanode
	mkdir /usr/local/hadoop/logs
	chown -fR vagrant /usr/local/hadoop/logs
}

function setupEnvVars {
	echo "creating java environment variables"
	#if fileExists $JAVA_ARCHIVE; then
	#	echo export JAVA_HOME=/usr/local/jdk1.7.0_51 >> /etc/profile.d/java.sh
	#else
	#	echo export JAVA_HOME=/usr/lib/jvm/jre >> /etc/profile.d/java.sh
	#fi
	echo export JAVA_HOME=/usr/local/java >> /etc/profile.d/java.sh
	echo export PATH=\${JAVA_HOME}/bin:\${PATH} >> /etc/profile.d/java.sh
	
	echo "creating hadoop environment variables"
	cp -f /vagrant/resources/hadoop.sh /etc/profile.d/hadoop.sh
}

function setupHadoopService {
	echo "setting up hadoop service"
	cp -f /vagrant/resources/hadoop /etc/init.d/hadoop
	chmod 777 /etc/init.d/hadoop
	chkconfig --level 2345 hadoop on
}

function setupNameNode {
	echo "setting up namenode"
	/usr/local/hadoop/bin/hdfs namenode -format myhadoop
}

function startHadoopService {
	echo "starting hadoop service"
	service hadoop start
}

function installSpark {
	if fileExists $SPARK_ARCHIVE; then
		installLocalSpark
	else
		installRemoteSpark
	fi
}

function installHadoop {
	if fileExists $HADOOP_ARCHIVE; then
		installLocalHadoop
	else
		installRemoteHadoop
	fi
}

function installJava {
	if fileExists $JAVA_ARCHIVE; then
		installLocalJava
	else
		installRemoteJava
	fi
}

function initHdfsTempDir {
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -mkdir /tmp
	$HADOOP_PREFIX/bin/hdfs --config $HADOOP_PREFIX/etc/hadoop dfs -chmod -R 777 /tmp
}

disableFirewall
installHostsFile
installJava
installHadoop
installSpark
setupJava
setupHadoop
setupEnvVars
setupNameNode
setupHadoopService
startHadoopService
setupSpark
setupSparkThriftService
startSparkThriftService
initHdfsTempDir
