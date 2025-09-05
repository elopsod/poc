# Root CA
openssl genrsa -out rootCA.key 4096
openssl req -new -x509 -sha256 -key rootCA.key -subj "/C=CA/ST=APP/L=LOCAL/O=ORG/OU=UNIT/CN=ROOT" -out rootCA.crt -days 36500

# Certificate
openssl genrsa -out server.key 4096
openssl req -new -key server.key -subj "/C=CA/ST=APP/L=LOCAL/O=ORG/OU=UNIT/CN=default" -out server.csr

openssl x509 -req  -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out server.crt -days 36500 -sha256 -extfile \
    <(printf "
        subjectAltName=\
          IP.1:127.0.0.1,\
          DNS:localhost,\
          DNS:keycloak,\
          DNS:keycloak.local,\
          DNS:keycloak.loc,\
          DNS:*,\
          DNS:*.nip.io
        keyUsage=critical,digitalSignature,keyEncipherment
        extendedKeyUsage=serverAuth,clientAuth
        basicConstraints=critical,CA:FALSE
        authorityKeyIdentifier=keyid,issuer
      ")


chmod 644 server.key
chmod 644 server.crt
