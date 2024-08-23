sudo amazon-linux-extras disable nginx1


sudo vi /etc/yum.repos.d/nginx.repo


[nginx-stable]
name=nginx stable repo
baseurl=https://nginx.org/packages/amzn2/2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key



sudo yum clean all


sudo yum makecache

sudo yum install nginx

sudo yum swap nginx-core nginx
