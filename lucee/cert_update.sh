#Lucee version 6.0.0

echo | openssl s_client -connect ins.com:443 -showcerts | openssl x509 -outform PEM > ins_cert.pem

sudo keytool -import -trustcacerts -keystore /opt/lucee/jdk/jre/jre/lib/security/cacerts -storepass changeit -noprompt -alias ins -file ins_cert.pem

sudo keytool -import -trustcacerts -keystore /opt/lucee/tomcat/lucee-server/context/securitycacerts  -storepass changeit -noprompt -alias ins -file sins_cert.pem

restart
