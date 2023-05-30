#!/bin/bash
PEM_WORKING_DIRECTORY="pem"
TRUSTSTORE_WORKING_DIRECTORY="truststore"
DEFAULT_TRUSTSTORE_FILE="kafka.truststore.jks"
ALIAS="CARoot"
PASSWORD="${PASSWORD:-supersecret}"

KEY_FILE=$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILE

rm -rf $PEM_WORKING_DIRECTORY && mkdir $PEM_WORKING_DIRECTORY

echo $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILE
echo "Generating certificate.pem"
keytool -exportcert -alias $ALIAS -keystore $KEY_FILE -rfc \
  -file $PEM_WORKING_DIRECTORY/certificate.pem -storepass $PASSWORD

echo "Generating key.pem"
keytool -v -importkeystore -srckeystore $KEY_FILE -srcalias $ALIAS \
  -destkeystore $PEM_WORKING_DIRECTORY/cert_and_key.p12 -deststoretype PKCS12 \
  -storepass $PASSWORD -srcstorepass $PASSWORD

openssl pkcs12 -in $PEM_WORKING_DIRECTORY/cert_and_key.p12 \
  -nodes -nocerts -out $PEM_WORKING_DIRECTORY/key.pem -passin pass:$PASSWORD

rm $PEM_WORKING_DIRECTORY/cert_and_key.p12

echo "Generating CARoot.pem"
keytool -exportcert -alias $ALIAS -keystore $KEY_FILE -rfc \
  -file $PEM_WORKING_DIRECTORY/CARoot.pem -storepass $PASSWORD