# Configure Kafka Broker
```
sudo vi ~/kafka/config/server.properties  
```
=> replace content by [this one](./server.properties)

# Create JAAS file
use [this template](.kafka_server_jaas.conf) and save it under ~/kafka/config/kafka_server_jaas.conf

# Modify systemd script
modify _kafka.service_ by applying [this template](./kafka.service) to /etc/systemd/system/kafka.service  
followed by executing:
```
sudo systemctl daemon-reload
```

# Extend security_groups
AWS mgm console => Kafka EC2 instance => security_group => add port 9094 to be accessible by "my ip"

AWS mgm console => Kerberos EC2 instance => security_group => add *UDP* port 88 to be accessible from *Kafka EC2 instance AND "my ip"*


# Restart Kafka
```
sudo systemctl restart kafka

sudo systemctl status kafka
```
