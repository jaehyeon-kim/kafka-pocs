#!/usr/bin/env bash
 
set -eu

COUNTRY="${COUNTRY:-AU}"
STATE="${STATE:-}"
OU="${OU:-service-users}"
CN="${CN:-kafka-admin}"
LOCATION="${CITY:-}"
PASSWORD="${PASSWORD:-supersecret}"

VALIDITY_IN_DAYS=3650
DEFAULT_TRUSTSTORE_FILENAME="kafka.truststore.jks"
TRUSTSTORE_WORKING_DIRECTORY="truststore"
KEYSTORE_WORKING_DIRECTORY="keystore"
CA_CERT_FILE="ca-cert"
KEYSTORE_SIGN_REQUEST="cert-file"
KEYSTORE_SIGN_REQUEST_SRL="ca-cert.srl"
KEYSTORE_SIGNED_CERT="cert-signed"
KAFKA_HOSTS_FILE="kafka-hosts.txt"
 
function file_exists_and_exit() {
echo "'$1' cannot exist. Move or delete it before"
echo "re-running this script."
exit 1
}
 
if [ -e "$KEYSTORE_WORKING_DIRECTORY" ]; then
  file_exists_and_exit $KEYSTORE_WORKING_DIRECTORY
fi
 
if [ -e "$CA_CERT_FILE" ]; then
  file_exists_and_exit $CA_CERT_FILE
fi
 
if [ -e "$KEYSTORE_SIGN_REQUEST" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST
fi
 
if [ -e "$KEYSTORE_SIGN_REQUEST_SRL" ]; then
  file_exists_and_exit $KEYSTORE_SIGN_REQUEST_SRL
fi
 
if [ -e "$KEYSTORE_SIGNED_CERT" ]; then
  file_exists_and_exit $KEYSTORE_SIGNED_CERT
fi
 
if [ ! -f "$KAFKA_HOSTS_FILE" ]; then
  echo "'$KAFKA_HOSTS_FILE' does not exists. Create this file"
  exit 1
fi
 
echo "Welcome to the Kafka SSL keystore and trust store generator script."
 
trust_store_file=""
trust_store_private_key_file=""
 
if [ ! -e "$TRUSTSTORE_WORKING_DIRECTORY" ]; then
  mkdir $TRUSTSTORE_WORKING_DIRECTORY
  echo
  echo "OK, we'll generate a trust store and associated private key."
  echo
  echo "First, the private key."
  echo
 
  openssl req -new -x509 -keyout $TRUSTSTORE_WORKING_DIRECTORY/ca-key \
    -out $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -days $VALIDITY_IN_DAYS -nodes \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$OU/CN=$CN"
 
  trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"
 
  echo
  echo "Two files were created:"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-key -- the private key used later to"
  echo " sign certificates"
  echo " - $TRUSTSTORE_WORKING_DIRECTORY/ca-cert -- the certificate that will be"
  echo " stored in the trust store in a moment and serve as the certificate"
  echo " authority (CA). Once this certificate has been stored in the trust"
  echo " store, it will be deleted. It can be retrieved from the trust store via:"
  echo " $ keytool -keystore <trust-store-file> -export -alias CARoot -rfc"
 
  echo
  echo "Now the trust store will be generated from the certificate."
  echo
 
  keytool -keystore $TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME \
    -alias CARoot -import -file $TRUSTSTORE_WORKING_DIRECTORY/ca-cert \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$CN" -keypass $PASSWORD -storepass $PASSWORD
 
  trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"
 
  echo
  echo "$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME was created."
 
  # don't need the cert because it's in the trust store.
  # rm $TRUSTSTORE_WORKING_DIRECTORY/$CA_CERT_FILE
 
  echo
  echo "Continuing with:"
  echo " - trust store file: $trust_store_file"
  echo " - trust store private key: $trust_store_private_key_file"
 
else
  trust_store_private_key_file="$TRUSTSTORE_WORKING_DIRECTORY/ca-key"
  trust_store_file="$TRUSTSTORE_WORKING_DIRECTORY/$DEFAULT_TRUSTSTORE_FILENAME"
fi
 
mkdir $KEYSTORE_WORKING_DIRECTORY
 
while read -r KAFKA_HOST || [ -n "$KAFKA_HOST" ]; do
  echo
  echo "Now, a keystore will be generated. Each broker and logical client needs its own"
  echo "keystore. This script will create only one keystore. Run this script multiple"
  echo "times for multiple keystores."
  echo
  echo " NOTE: currently in Kafka, the Common Name (CN) does not need to be the FQDN of"
  echo " this host. However, at some point, this may change. As such, make the CN"
  echo " the FQDN. Some operating systems call the CN prompt 'first / last name'"
 
  # To learn more about CNs and FQDNs, read:
  # https://docs.oracle.com/javase/7/docs/api/javax/net/ssl/X509ExtendedTrustManager.html
 
  KEY_STORE_FILE_NAME="$KAFKA_HOST.server.keystore.jks"
 
  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/"$KEY_STORE_FILE_NAME" \
    -alias localhost -validity $VALIDITY_IN_DAYS -genkey -keyalg RSA \
    -noprompt -dname "C=$COUNTRY, ST=$STATE, L=$LOCATION, O=$OU, CN=$KAFKA_HOST" \
    -keypass $PASSWORD -storepass $PASSWORD
 
  echo
  echo "'$KEYSTORE_WORKING_DIRECTORY/$KEY_STORE_FILE_NAME' now contains a key pair and a"
  echo "self-signed certificate. Again, this keystore can only be used for one broker or"
  echo "one logical client. Other brokers or clients need to generate their own keystores."
 
  echo
  echo "Fetching the certificate from the trust store and storing in $CA_CERT_FILE."
  echo
 
  keytool -keystore $trust_store_file -export -alias CARoot -rfc -file $CA_CERT_FILE -keypass $PASSWORD -storepass $PASSWORD
 
  echo
  echo "Now a certificate signing request will be made to the keystore."
  echo
  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/"$KEY_STORE_FILE_NAME" -alias localhost \
    -certreq -file $KEYSTORE_SIGN_REQUEST -keypass $PASSWORD -storepass $PASSWORD
 
  echo
  echo "Now the trust store's private key (CA) will sign the keystore's certificate."
  echo
  openssl x509 -req -CA $CA_CERT_FILE -CAkey $trust_store_private_key_file \
    -in $KEYSTORE_SIGN_REQUEST -out $KEYSTORE_SIGNED_CERT \
    -days $VALIDITY_IN_DAYS -CAcreateserial
  # creates $KEYSTORE_SIGN_REQUEST_SRL which is never used or needed.
 
  echo
  echo "Now the CA will be imported into the keystore."
  echo
  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/"$KEY_STORE_FILE_NAME" -alias CARoot \
    -import -file $CA_CERT_FILE -keypass $PASSWORD -storepass $PASSWORD -noprompt
 
  echo
  echo "Now the keystore's signed certificate will be imported back into the keystore."
  echo
  keytool -keystore $KEYSTORE_WORKING_DIRECTORY/"$KEY_STORE_FILE_NAME" -alias localhost -import \
    -file $KEYSTORE_SIGNED_CERT -keypass $PASSWORD -storepass $PASSWORD
  rm $CA_CERT_FILE # delete the trust store cert because it's stored in the trust store. 

  echo
  echo "All done!"
  echo
  echo "Deleting intermediate files. They are:"
  echo " - '$KEYSTORE_SIGN_REQUEST_SRL': CA serial number"
  echo " - '$KEYSTORE_SIGN_REQUEST': the keystore's certificate signing request"
  echo " (that was fulfilled)"
  echo " - '$KEYSTORE_SIGNED_CERT': the keystore's certificate, signed by the CA, and stored back"
  echo " into the keystore"

  rm $KEYSTORE_SIGN_REQUEST_SRL
  rm $KEYSTORE_SIGN_REQUEST
  rm $KEYSTORE_SIGNED_CERT
done < "$KAFKA_HOSTS_FILE"