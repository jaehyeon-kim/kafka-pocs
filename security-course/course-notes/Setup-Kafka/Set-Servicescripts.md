# add service scripts for managing Kafka/Zookeeper
### stop Kafka & Zookeeper first
```
~/kafka/bin/kafka-server-stop
~/kafka/bin/zookeeper-server-stop
```
### /etc/systemd/system/zookeeper.service
Copy file [zookeeper.service](./zookeeper.service) and store it as   
/etc/systemd/system/zookeeper.service

sudo vi /etc/systemd/system/zookeeper.service

### /etc/systemd/system/kafka.service
Copy file [kafka.service](./kafka.service) and store it as   
/etc/systemd/system/kafka.service

sudo vi /etc/systemd/system/kafka.service

### activating the systemd scripts
```
sudo systemctl enable zookeeper
sudo systemctl enable kafka
```
### service management via systemd
```
sudo systemctl status zookeeper
sudo systemctl status kafka

sudo systemctl start zookeeper
sudo systemctl start kafka

sudo systemctl stop zookeeper
sudo systemctl stop kafka
```
