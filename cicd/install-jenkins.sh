sudo apt update
sudo apt install -y openjdk-21-jdk
java -version
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc   https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl status jenkins --no-pager
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "open localhost:8080/"
echo "register new user -> admin/password"
echo "sudo systemctl status jenkins"
echo "sudo systemctl stop jenkins"
echo "sudo systemctl start jenkins"
