# on local computer
## create a CLIENT certificate !! put your LOCAL hostname after "CN=" and specify an alias
```
export CLIPASS=clientpass
cd ~
cd ssl

keytool -genkey -keystore kafka.client.keystore.jks -validity 365 -storepass $CLIPASS -keypass $CLIPASS  -dname "CN=mylaptop" -alias my-local-pc -storetype pkcs12
#> ll

keytool -list -v -keystore kafka.client.keystore.jks
```

## create a certification request file, to be signed by the CA
```
keytool -keystore kafka.client.keystore.jks -certreq -file client-cert-sign-request -alias my-local-pc -storepass $CLIPASS -keypass $CLIPASS
#> ll
```
## copy the request file to EC2 instance where we setup our CA
```
scp -i ~/kafka-security.pem client-cert-sign-request ubuntu@ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:/tmp/
```
# switch to EC2 instance, hence to the CA
## sign the server certificate => output: file "cert-signed"
!! execute this in terminal of your EC2 instance, hence where we setup the CA !!
```
cd ~/ssl
export SRVPASS=serversecret
openssl x509 -req -CA ca-cert -CAkey ca-key -in /tmp/client-cert-sign-request -out /tmp/client-cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS
#> ll
```

# switch back to local computer
## copy the signed certificate from EC2 instance to local computer and import to keystore
```
cd ~/ssl
scp -i ~/kafka-security.pem ubuntu@ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:/tmp/client-cert-signed  .

keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt
keytool -keystore kafka.client.keystore.jks -import -file client-cert-signed -alias my-local-pc -storepass $CLIPASS -keypass $CLIPASS -noprompt
```

keytool -list -v -keystore kafka.client.keystore.jks

# configure Kafka Broker
  * use [server.properties](./server.properties), the new property is *ssl.client.auth*
  * restart Kafka  

# TEST
use [client-ssl-auth.properties](./client-ssl-auth.properties) and execute console producer/-consumer
```
~/kafka/bin/kafka-console-producer.sh --broker-list ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:9093 --topic kafka-security-topic --producer.config ~/ssl/client-ssl-auth.properties
~/kafka/bin/kafka-console-consumer.sh --bootstrap-server ec2-18-196-169-2.eu-central-1.compute.amazonaws.com:9093 --topic kafka-security-topic --consumer.config ~/ssl/client-ssl-auth.properties
```
