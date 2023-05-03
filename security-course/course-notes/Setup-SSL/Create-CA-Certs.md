# Setup CA
create CA => result: file ca-cert and the priv.key ca-key  

```
mkdir ssl
cd ssl 
openssl req -new -newkey rsa:4096 -days 365 -x509 -subj "/CN=Kafka-Security-CA" -keyout ca-key -out ca-cert -nodes

cat ca-cert
cat ca-key
keytool -printcert -v -file ca-cert
```


### Add-On: public certificates check
```
echo |
  openssl s_client -connect www.google.com:443 2>/dev/null |
  openssl x509 -noout -text -certopt no_header,no_version,no_serial,no_signame,no_pubkey,no_sigdump,no_aux -subject -nameopt multiline -issuer
```
