#!/bin/bash

sudo apt-get install -y openjdk-8-jdk

wget https://archive.apache.org/dist/hadoop/core/hadoop-2.7.2/hadoop-2.7.2.tar.gz
tar -xvzf hadoop-2.7.2.tar.gz
mv hadoop-2.7.2 hadoop

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ >> .bashrc
echo export HADOOP_PREFIX=~/hadoop >> .bashrc
echo export HADOOP_YARN_HOME=~/hadoop >> .bashrc
echo export HADOOP_HOME=~/hadoop >> .bashrc
echo export HADOOP_CONF_DIR=~/hadoop/etc/hadoop >> .bashrc
echo export YARN_CONF_DIR=~/hadoop/etc/hadoop >> .bashrc
source .bashrc

sed -i '1iexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64' ~/hadoop/etc/hadoop/hadoop-env.sh

sudo mkdir /dev/hdfs
sudo chmod 777 /dev/hdfs 

rm ~/hadoop/etc/hadoop/core-site.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>

<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://ctl-0:9000/</value>
  </property>

  <property>
    <name>hadoop.tmp.dir</name>
    <value>/dev/hdfs</value>
  </property>

</configuration>" >> ~/hadoop/etc/hadoop/core-site.xml

rm ~/hadoop/etc/hadoop/hdfs-site.xml
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>

  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.blocksize</name>
    <value>268435456</value>
  </property>

  <property>
    <name>dfs.namenode.handler.count</name>
    <value>100</value>
  </property>

</configuration>" >> ~/hadoop/etc/hadoop/hdfs-site.xml

rm ~/hadoop/etc/hadoop/yarn-site.xml
echo "<?xml version=\"1.0\"?>
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>"$1"</value>
  </property>
  <property>
    <name>yarn.resourcemanager.scheduler.class</name>
    <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
  </property>
  <property>
    <name>yarn.scheduler.fair.allocation.file</name>
    <value>/users/F19_TIP/hadoop/etc/hadoop/fair-scheduler.xml</value>
  </property>
  <property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>32</value>
  </property>
  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>65536</value>
  </property></configuration>" >> ~/hadoop/etc/hadoop/yarn-site.xml


echo "<?xml version=\"1.0\"?>
<allocations>
<defaultQueueSchedulingPolicy>drf</defaultQueueSchedulingPolicy>
<queue name=\"queue0\">
        <weight>1</weight>
        <allowPreemptionFrom>false</allowPreemptionFrom>
        <schedulingPolicy>fifo</schedulingPolicy>
</queue>
<queue name=\"queue1\">
        <weight>1</weight>
        <allowPreemptionFrom>true</allowPreemptionFrom>
</queue>
</allocations>" >> ~/hadoop/etc/hadoop/fair-scheduler.xml

rm ~/hadoop/etc/hadoop/slaves
echo "cp-1-0
cp-2-0
cp-3-0
cp-4-0" >> ~/hadoop/etc/hadoop/slaves


if [ "master" == "$2" ]; then
~/hadoop/bin/hdfs namenode -format hdfs 
~/hadoop/sbin/stop-all.sh
~/hadoop/sbin/start-dfs.sh 
~/hadoop/sbin/start-yarn.sh 
wget https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz
tar -xvzf protobuf-2.5.0.tar.gz 
cd protobuf-2.5.0
sudo ./configure 
sudo make 
sudo make check
sudo make install
sudo ldconfig

wget http://apache.claz.org/tez/0.9.0/apache-tez-0.9.0-src.tar.gz 
tar -xvzf apache-tez-0.9.0-src.tar.gz
cd apache-tez-0.9.0-src
mvn clean package -DskipTests=true -Dmaven.javadoc.skip=true

mkdir hadoop/tez_jars
tar -xvzf apache-tez-0.9.0-src/tez-dist/target/tez-0.9.0-minimal.tar.gz -C hadoop/tez_jars

hadoop/bin/hadoop dfs -mkdir /apps
hadoop/bin/hadoop dfs -mkdir /apps/tez
hadoop/bin/hadoop dfs -copyFromLocal apache-tez-0.9.0-src/tez-dist/target/tez-0.9.0.tar.gz /apps/tez/

echo "export HADOOP_CLASSPATH=hadoop/etc/tez:hadoop/tez_jars/*:hadoop/tez_jars/lib/*" >> ~/hadoop/etc/hadoop/hadoop-env.sh

mkdir ~/hadoop/etc/tez
echo "<?xml version=\"1.0\"?>
    <configuration>
         <property>
             <name>tez.lib.uris</name>
             <value>hdfs://ctl:9000//apps/tez/tez-0.9.0.tar.gz</value>
         </property>
         <property>
              <description>URL for where the Tez UI is hosted</description>
              <name>tez.tez-ui.history-url.base</name>
              <value>http://<master_host>:9999/tez-ui/</value>
         </property>
    </configuration>" >> ~/hadoop/etc/tez/tez-site.xml



echo "abc abc def def" > input.txt
hadoop/bin/hadoop dfs -copyFromLocal input.txt
hadoop/bin/hadoop jar hadoop/tez_jars/tez-examples-0.9.0.jar wordcount input.txt output.txt
fi

echo "DONE"

exit 0