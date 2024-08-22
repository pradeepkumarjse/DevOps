# installation on ubuntu 24

## Step 1: update the system
sudo apt update

## Step 2: Install Java
sudo apt install openjdk-17-jdk
verify installation
java -version

## Step 3: Add Jenkins Repository

### Import the GPG key:
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
/usr/share/keyrings/jenkins-keyring.asc > /dev/null
### Add the Jenkins repository:
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null

## Step 4: Install Jenkins
sudo apt update
sudo apt install jenkins

## Step 5: Start and Enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

## Step 7: Access Jenkins
Open a web browser and go to http://server_ip:8080

