# Installation of Apache Kafka
## install Kafka package
ssh into your EC2 instance
```
sudo apt-get update
sudo apt-get install -y wget net-tools netcat tar openjdk-8-jdk
wget http://mirror.softaculous.com/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz
tar -xzf kafka_2.11-1.0.0.tgz
ln -s kafka_2.11-1.0.0 kafka
java -version
```
## start Zookeeper
ssh into your EC2 instance  
start zookeeper
```
~/kafka/bin/zookeeper-server-start.sh -daemon ~/kafka/config/zookeeper.properties
```
check if zookeeper is running
```
tail -n 5 ~/kafka/logs/zookeeper.out

echo "ruok" | nc localhost 2181 ; echo
```

## start Kafka
ssh into your EC2 instance
Start Kafka Broker
```
~/kafka/bin/kafka-server-start.sh -daemon ~/kafka/config/server.properties
```
Check Broker status
```
tail -n 10 ~/kafka/logs/kafkaServer.out
netstat -pant | grep ":9092"
```
