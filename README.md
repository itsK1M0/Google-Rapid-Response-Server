# GRR Rapid Response Server Installation Guide

## 🚀 Introduction

This guide provides step-by-step instructions for installing and configuring **GRR Rapid Response** on Ubuntu Server 22.04. GRR is an incident response framework that enables remote live forensics and endpoint management.

**Architecture Stack:**
- Ubuntu Server 22.04
- MySQL Database
- Fleetspeak Communication Framework
- GRR Server Components

---

## 📋 Prerequisites & System Preparation

### 1. System Update & Essential Dependencies

```bash
# Update package lists and upgrade existing packages
sudo apt update && sudo apt upgrade -y

# Install essential dependencies
sudo apt install -y wget curl gnupg lsb-release build-essential python3-pip python3-venv

# Reboot to apply updates
sudo reboot
```

**Why these packages?**  
They provide the foundation for downloading, compiling dependencies, and ensuring proper GRR execution.

---

## 🗄️ MySQL Installation & Configuration

### 2. Install MySQL Server

```bash
# Install MySQL
sudo apt install -y mysql-server

# Enable and start MySQL service
sudo systemctl enable mysql
sudo systemctl start mysql
```

### 3. Secure MySQL Installation

```bash
# Access MySQL as root
sudo mysql

# Set root password (Replace XXXX with strong password)
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'XXXX';
FLUSH PRIVILEGES;
EXIT;
```

⚠️ **Security Note:** Use a strong password in production environments.

### 4. Create Databases & Users

```bash
# Login to MySQL
mysql -u root -p

# Create databases
CREATE DATABASE grr;
CREATE DATABASE fleetspeak;

# Create users
CREATE USER 'grr'@'localhost' IDENTIFIED BY 'grrpasswd';
CREATE USER 'fleetspeak'@'localhost' IDENTIFIED BY 'fleetspeakpasswd';

# Grant privileges
GRANT ALL PRIVILEGES ON grr.* TO 'grr'@'localhost';
GRANT ALL PRIVILEGES ON fleetspeak.* TO 'fleetspeak'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 5. Advanced MySQL Configuration

```bash
# Edit MySQL configuration
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf
```

Add under `[mysqld]` section:
```
log_bin_trust_function_creators = 1
```

```bash
# Restart MySQL
sudo systemctl restart mysql
```

🔍 **Explanation:** This option allows GRR to create MySQL functions without binlog restrictions.

---

## 🔧 GRR Server Installation

### 6. Download and Install GRR Package

```bash
# Download GRR server package
wget https://github.com/google/grr/releases/download/v3.4.7.1-release/grr-server_3.4.7-1_amd64.deb

# Install the package
sudo apt install ./grr-server_3.4.7-1_amd64.deb -y
```

### 7. Interactive Configuration Wizard

During installation, you'll be prompted with configuration questions:

#### -=Setting Basic Configuration Parameters=-
- Use Fleetspeak ? [Yn]: [Y]: **Y**
-  hostname : **SERVER_IP**
- Fleetspeak public HTTPS port [4443]: **4443**
- Fleetspeak MySQL Host [localhost]: **127.0.0.1**
- Fleetspeak MySQL Port (0 for local socket) [3306]: **3306**
- Fleetspeak MySQL Database [fleetspeak]: **fleetspeak**
- Fleetspeak MySQL Username [root]: **fleetspeak**
- Please enter password for database user fleetspeak: **fleetspeak's passwd you've set in DBs**
Successfully connected to MySQL with the given configuration.

#### -=GRR Datastore=-
- MySQL Host [localhost]: **127.0.0.1**
- MySQL Port (0 for local socket) [0]: **3306**
- MySQL Database [grr]: **grr**
- MySQL Username [root]: **grr**
- Please enter password for database user grr: **grr's passwd you've set in DBs**
- Configure SSL connections for MySQL? [yN]: [N]: **N**
Successfully connected to MySQL with the provided details.

#### -=URLs Configuration=- :
- AdminUI URL [http://[YOUR_SERVER_IP]:8000/] : **PRESS_ENTER**
- Frontend URL [http://[YOUR_SERVER_IP]:8000/] : **PRESS_ENTER**

#### -=Email Configuration=-:
- Email settings: Configure according to your environment or skip it by **PRESSING ENTER**

#### -=Admin Account=-:
Adding GRR Admin User
- Please enter password for user 'admin': **SET A STRONG PASSWORD**
  you'll use this password to login to the webpage 

#### -=Repackaging clients with new configuration=-:
Server debs include client templates. Re-download templates? [yN]: [N]: **N**
Repack client templates? [Yn]: [Y]: **Y**

#### -=Restart Services=-:
- Restart services for new configuration to take effects? [Yn] [Y]: **yes**

### 8. Enable Services at Boot

```bash
sudo systemctl enable mysql
sudo systemctl enable fleetspeak-server
sudo systemctl enable grr-server
```

🔍 **Explanation:** Ensures services automatically start after server reboot.

---

## 👨‍💼 GRR Client Installation (Endpoint Agents)

### 9. Download Client Installers

This section describes the simplest method to make GRR client installers available for download to your endpoints.

### 🚀 Quick Method: Python Built-in HTTP Server 

#### On GRR server Navigate to the installers directory:

```bash
cd /usr/share/grr-server/executables/installers
```
Start the HTTP server on port 8080:

```bash
sudo python3 -m http.server 8080
```

#### Access from Anywhere:
Open a web browser on any machine in your network and navigate to:

```bash
http://[GRR_SERVER_IP]:8080/
```
You will see a directory listing with all available GRR client installers:
- dbg_GRR_3.4.7.1_amd64.msi (For admins who want detailed logs for troubleshooting or debugging) 
- grr_3.4.7.1_amd64.changes (Just text)
- grr_3.4.7.1_amd64.deb     (Debian/Ubuntu)
- GRR_3.4.7.1_amd64.msi     (Windows Installer)
- grr_3.4.7.1_amd64.pkg     (macOS installer)
- grr_3.4.7.1_amd64.rpm     (RedHat/CentOS/Fedora)

Simply click on any file to download it directly to your endpoint.

### 10. Deploy Clients to Endpoints

#### For Windows:
1. Download the Windows installer
2.  Run: `grr_[version]_amd64.exe`

#### For Linux:
```bash
# Ubuntu/Debian
sudo dpkg -i grr_[version]_amd64.deb

# RHEL/CentOS
sudo rpm -i grr-[version].x86_64.rpm
```

#### For macOS:
```bash
# Install via pkg
sudo installer -pkg grr_[version]_amd64.pkg -target /
```

### 11. Client Configuration

Clients automatically register with the server using the configuration set during installation. You can verify client connections in the GRR Admin UI.

### 12. Approve Clients in Admin UI

1. Access GRR Admin UI: `http://[SERVER_IP]:8000`
2. Login with admin credentials
3. Press the search Box and **Hit Enter**

---

## 🛠️ Service Management

### 13. Automated GRR Service Shutdown & Status Script

To avoid manual mistakes and ensure a clean shutdown sequence, this repository includes a script that automatically:

- Stops GRR services in the correct order  
- Prevents database corruption  
- Displays the status of all services after execution

#### What the Script Does

The script performs the following actions in order:

1. Stops `grr-server`
2. Stops `fleetspeak-server`
3. Stops `mysql`
4. Displays the status of all services
5. Safely powers off the system

⚠️ **The shutdown order is critical** to ensure data integrity and avoid MySQL corruption.

---

#### Download the Script

Since the script is included in this repository, simply clone the repository:

```bash
git clone https://github.com/itsK1M0/Google-Rapid-Response-Server.git
cd <your-repository>
```

#### Make the sccript Executable :

```bash
chmod +x shutdown_grr.sh
```

#### Run the script :

Execute the script with root privileges:

```bash
sudo ./shutdown_grr.sh
```
After execution, the script will display the status of all services so you can immediately verify that everything was stopped correctly before shutdown.

## 🔐 SSH Access for Remote Management (Optional)

### 15. Enable SSH Server

**Method 1: During Ubuntu Installation**  
- Check "OpenSSH server" option during OS installation

**Method 2: Post-Installation**

```bash
# Install SSH server
sudo apt install openssh-server

# Start and enable SSH
sudo systemctl start ssh
sudo systemctl enable ssh

# Verify status
sudo systemctl status ssh
```

### 16. Connect from Host Machine

```bash
ssh username@SERVER_IP
```

---

## 🎯 Access & Verification

### 17. Access GRR Admin Interface

- URL: `http://[YOUR_SERVER_IP]:8000`
- Username: **admin**
- Password: **[Your admin password]**

### 18. Verify Installation

1. **Check Services:** All three services (MySQL, Fleetspeak, GRR) should be running
2. **Access Web UI:** Login should be successful
3. **Test Client Connection:** Install a client and verify it appears in the Admin UI
4. **Run First Hunt:** Create a simple file find hunt to test functionality

---

## 📊 Post-Installation Configuration

### 19. Configure Email Notifications (Optional)

```bash
# Edit GRR config
sudo vi /etc/grr/server.local.yaml

# Add email configuration
Email.from_address: "grr@yourdomain.com"
Email.smtp_server: "smtp.yourdomain.com"
Email.smtp_port: 587
Email.smtp_username: "username"
Email.smtp_password: "password"
```

### 20. Enable SSL/TLS (Production)

```bash
# Generate certificates or use Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Configure Nginx as reverse proxy
sudo apt install nginx
# Configure Nginx to proxy to GRR on ports 8000/8080 with SSL
```

---

## 🚨 Troubleshooting Common Issues

### Issue: MySQL Connection Errors
```bash
# Verify MySQL is running
sudo systemctl status mysql

# Check MySQL logs
sudo tail -f /var/log/mysql/error.log

# Test connection
mysql -u grr -p -h localhost
```

### Issue: GRR Services Not Starting
```bash
# Check logs
sudo journalctl -u grr-server -n 50

# Verify configuration
sudo grr_config_updater check_config
```

### Issue: Clients Not Appearing
- Check firewall rules (ports 8080, 8000)
- Verify client installer configuration
- Check Fleetspeak service status

---

## 📈 Next Steps & Best Practices

1. **Regular Backups:** Schedule MySQL database backups
2. **Monitoring:** Set up monitoring for GRR services
3. **Client Deployment:** Automate client deployment using GPO, MDM, or configuration management
4. **User Training:** Train incident responders on GRR capabilities
5. **Integration:** Explore integration with SIEM and ticketing systems

---

## 🎉 Conclusion

Your GRR Rapid Response server is now fully operational! You can:

✅ Perform remote forensic investigations  
✅ Manage endpoints at scale  
✅ Execute hunts and collect artifacts  
✅ Respond to security incidents efficiently  

**Remember:** GRR is a powerful tool - ensure proper access controls and audit logging are in place for production use.

---

## 📚 Additional Resources

- [GRR Official Documentation](https://grr-doc.readthedocs.io/)
- [GRR GitHub Repository](https://github.com/google/grr)
- [Fleetspeak Documentation](https://github.com/google/fleetspeak)
- [GRR Community Discussions](https://groups.google.com/g/grr-users)

---

**⚠️ Security Disclaimer:**  
This guide is for educational and authorized testing purposes. Ensure compliance with organizational policies and legal requirements before deploying in production environments.

---

## 🖼️ Recommended Screenshots for Documentation

1. **GRR Admin UI Dashboard** - Main interface showing connected clients
2. **MySQL Configuration** - Showing database setup
3. **Service Status** - All three services running
4. **Client Approval Screen** - Pending clients in Admin UI
5. **Successful Hunt Results** - First hunt execution results
6. **Network Diagram** - Architecture overview
7. **Command Line Installation** - Key installation steps
