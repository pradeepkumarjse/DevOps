sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

sudo chmod +x /usr/local/bin/gitlab-runner

sudo gitlab-runner install --user=ubuntu

sudo gitlab-runner start

sudo gitlab-runner register  --url https://gitlab.com  --token your_token
