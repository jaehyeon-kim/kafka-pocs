
## create a server certificate !! put your public EC2-DNS here, after "CN="
```
export SRVPASS=serversecret
cd ssl

keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass $SRVPASS -keypass $SRVPASS  -dname "CN=ec2-18-196-169-2.eu-central-1.compute.amazonaws.com" -storetype pkcs12
#> ll

keytool -list -v -keystore kafka.server.keystore.jks
```

## create a certification request file, to be signed by the CA
```
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass $SRVPASS -keypass $SRVPASS
#> ll
```

## sign the server certificate => output: file "cert-signed"
```
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS
#> ll
```

## check certificates
### our local certificates
```
keytool -printcert -v -file cert-signed
keytool -list -v -keystore kafka.server.keystore.jks
```



# Trust the CA by creating a truststore and importing the ca-cert
```
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt

```
# Import CA and the signed server certificate into the keystore
```
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt
```

# Adjust Broker configuration  
Replace the server.properties in AWS, by using [this one](./server.properties).   
*Ensure that you set your public-DNS* !!

# Restart Kafka
```
sudo systemctl restart kafka
sudo systemctl status kafka  
```
# Verify Broker startup
```
sudo grep "EndPoint" /home/ubuntu/kafka/logs/server.log
```
# Adjust SecurityGroup to open port 9093

# Verify SSL config
from your local computer
```
openssl s_client -connect <<your-public-DNS>>:9093
```
