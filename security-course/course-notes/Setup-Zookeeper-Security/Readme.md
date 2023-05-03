# Zookeeper Authentication

## create Kerberos principal  
add principal for Zookeeper in KDC and create keytab.  
!! ensure you are using *INTERNAL DNS name* of your node !!

```
sudo kadmin.local -q "add_principal -randkey zookeeper/<<KAFKA-SERVER-INTERNAL-DNS>>@KAFKA.SECURE"

sudo kadmin.local -q "xst -kt /tmp/zookeeper.service.keytab zookeeper/<<KAFKA-SERVER-INTERNAL-DNS>>@KAFKA.SECURE"

sudo chmod a+r /tmp/zookeeper.service.keytab
```

copy keytab file to Zookeeper-Node, via local PC
```
scp -i ~/kafka-security.pem centos@<<KERBEROS-SERVER-PUBLIC-DNS>>:/tmp/zookeeper.service.keytab /tmp/

scp -i ~/kafka-security.pem /tmp/zookeeper.service.keytab ubuntu@<<KAFKA-SERVER-PUBLIC-DNS>>:/tmp/
```
## extend Zookeeper configuration
add Kerberos auth properties to config file _/home/ubuntu/kafka/config/zookeeper.properties_ . Use template [zookeeper.properties](./zookeeper.properties) to replace your server zookeeper configuration.

## create Zookeeper JAAS config  
create file _/home/ubuntu/kafka/config/zookeeper_jaas.conf_ , with content from [zookeeper_jaas.conf](./zookeeper_jaas.conf).

## extend Zookeeper service script  
add env _KAFKA_OPTS_ to the zookeeper service script. Use template [zookeeper.service](./zookeeper.service) to replace your server zookeeper configuration in _/etc/systemd/system/_.

## reconfigure Kafka's JAAS
add section for cennecting to Zookeeper to JAAS configuration _/home/ubuntu/kafka/config/kafka_server_jaas.conf_ . Use template [kafka_server_jaas.conf](./kafka_server_jaas.conf) to replace your existing JAAS config.

## restart Zookeeper&Kafka

```
sudo systemctl daemon-reload

sudo systemctl stop kafka
sudo systemctl restart zookeeper
sudo systemctl start kafka
```
## perform some tests / demo statements
create a manual znode with authenticated user
```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181
create /test-znode "just a test"
get /test-znode
getAcl /test-znode

create /protected-znode "znode sasl enabled" sasl:zookeeper/<<KAFKA-SERVER-INTERNAL-DNS>>@KAFKA.SECURE:cdwra
getAcl /protected-znode

```
tests with unauthenticated user, hence anonymous  

```
export KAFKA_OPTS=""
kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181
create /test-znode2 "znode from unauthorized user"
ls /test-znode2

ls /test-znode

## try to access the sasl-protected znode
ls /protected-znode
Authentication is not valid : /protected-znode

```
Kafka topics related queries  

```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181
ls /config/topics/kafka-security-topic
getAcl /config/topics/kafka-security-topic
```
Create new topics  

```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/kafka-topics.sh --zookeeper <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 --create --topic demotopic1 --replication-factor 1 --partitions 1
```
```
export KAFKA_OPTS=""
~/kafka/bin/kafka-topics.sh --zookeeper <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 --create --topic demotopic2 --replication-factor 1 --partitions 1
```

```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf

~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 getAcl /config/topics/demotopic1

~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 getAcl /config/topics/demotopic2

```

# extend Kafka & ZK config to force setting ACLs on znodes
## enable zookeeper ACL in Kafka config
add property ```zookeeper.set.acl=true``` to config _/home/ubuntu/kafka/config/server.properties_ by applying template [server.properties](./server.properties)

## extend Zookeeper config to remove host&Realm from Kerberos principal
add the following two lines to config file ```zookeeper.properties```
```
kerberos.removeHostFromPrincipal=true
kerberos.removeRealmFromPrincipal=true
```

## restart services
```
sudo systemctl restart zookeeper
sudo systemctl restart kafka
```

# Zookeeper tests

create a topic with authenticated user
```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/kafka-topics.sh --zookeeper <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 --create --topic secured-topic --replication-factor 1 --partitions 1

~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181

getAcl /config/topics/secured-topic

getAcl /config/topics/kafka-security-topic
```




# Zookeeper Super User
## create digest of password
```
export ZK_CLASSPATH=~/kafka/conf:~/kafka/libs/*
java -cp $ZK_CLASSPATH org.apache.zookeeper.server.auth.DigestAuthenticationProvider super:superpw
```
super:superpw->super:g9oN2HttPfn8MMWJZ2r45Np/LIA=

## use the digest user/pw for Zookeeper process startup
add the following to /etc/systemd/system/zookeeper.service KAFKA_OPTS property:
```-Dzookeeper.DigestAuthenticationProvider.superDigest=super:g9oN2HttPfn8MMWJZ2r45Np/LIA=```

## add digest auth to Zookeeper and check setting ACLs
```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181


addauth digest super:superpw
getAcl /config/topics/secured-topic
setAcl /config/topics/secured-topic world:anyone:r,sasl:zookeeper:cdrwa
setAcl /config/topics/secured-topic world:anyone:,sasl:zookeeper:cdrwa
```

# Migrate existing, non-secure topic znodes to secure ones
```
export KAFKA_OPTS=-Djava.security.auth.login.config=/home/ubuntu/kafka/config/kafka_server_jaas.conf
~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 getAcl /config/topics/kafka-security-topic
~/kafka/bin/zookeeper-security-migration.sh --zookeeper.connect <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 --zookeeper.acl secure
~/kafka/bin/zookeeper-shell.sh <<KAFKA-SERVER-EXTERNAL-DNS>>:2181 getAcl /config/topics/kafka-security-topic
```
