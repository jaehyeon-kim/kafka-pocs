# Testing Producer and Consumer from outside AWS
## SERVER side

## adjusting Security Group
login to AWS management console
goto your EC2 instance
click on the security group and add 2 rules, for ports   
  * 2181
  * 9092

## copy your public DNS of your instance
ec2-18-196-169-2.eu-central-1.compute.amazonaws.com

## adjust listener settings for Kafka
replace server.properties in your EC2 instance (under /home/ubuntu/kafka/config/) by [server.properties](./server.properties), *and* add your instance's public DNS in  
  * advertised.listeners
  * zookeeper.connect

## restart Kafka
```
sudo systemctl restart kafka

sudo systemctl status kafka
```

## CLIENT side
## setup Kafka on your computer
download Kafka binaries to your computer and perform the same steps as on your EC2 instance
```
sudo apt-get install -y wget net-tools netcat tar openjdk-8-jdk
wget http://mirror.softaculous.com/apache/kafka/1.0.0/kafka_2.11-1.0.0.tgz
tar -xzf kafka_2.11-1.0.0.tgz
ln -s kafka_2.11-1.0.0 kafka
```

## test Zookeeper availability
```
echo "ruok" | nc ec2-18-196-169-2.eu-central-1.compute.amazonaws.com 2181
```

## create a test topic
```
~/kafka/bin/kafka-topics.sh --zookeeper ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:2181 --create --topic kafka-security-topic --replication-factor 1 --partitions 2
```
```
~/kafka/bin/kafka-topics.sh --zookeeper ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:2181 --describe --topic kafka-security-topic
```

## start Producer
```
~/kafka/bin/kafka-console-producer.sh --broker-list ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:9092 --topic kafka-security-topic
```

## start Consumer
```
~/kafka/bin/kafka-console-consumer.sh --bootstrap-server ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:9092 --topic kafka-security-topic
```
