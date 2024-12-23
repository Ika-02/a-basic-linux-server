# 🐧 A Linux Project

This repository contains the scripts for the project I conducted with classmates over 4 days (3 days of work and 1 day of verification and presentation) on the Linux operating system, a cornerstone in the field of computing. The main objective was to explore the many facets of Linux, from its robust and flexible architecture to the configuration and use of its services.

## 🖥️ OS used

The choice of Red Hat Enterprise Linux (RHEL) for this project is motivated by its reputation for reliability and stability, which are essential for professional environments. The extensive technical support provided by Red Hat, including regular security updates, ensures the long-term stability of the server and meets compliance requirements.

We chose to install Linux without a graphical user interface (GUI) and in server mode to maximize available system resources, reduce the potential attack surface of the server, and promote automation and remote management.

## 🛠️ Services

We have configured the following services:
- **Chrony**: To allow clock synchronization of clients within our network.
- **NFS**: For public file sharing across the network.
- **Samba**: To enable interoperable SMB file sharing between Linux and Windows systems.
- **FTP**: For secure and efficient file transfer in the web folder between the server and clients.
- **Bind**: DNS server to link an IP to a domain name, allowing access to our users' sites via a subdomain.
- **Apache**: As a web server, Apache was configured to host sites using PHP for different users via VirtualHosts.
- **MySQL**: To provide a database for each site to store and manage data efficiently.
- **phpMyAdmin**: For web-based management of MySQL databases, offering a user-friendly interface to administer databases.

Additionally, we have implemented several services aimed at securing the use of these services:
- **Firewalld**: To manage and configure a dynamic firewall, providing protection against unauthorized access.
- **SELinux**: Enhances security by limiting user and process privileges and isolating system components.
- **Fail2ban**: To protect the server against malicious login attempts by blocking suspicious IP addresses in case of brute force attacks.
- **ClamAV**: To ensure antivirus protection, scanning files for potential threats.

## 🗂️ Partition and Backup Plans

During the project, we also created a detailed partition plan and a comprehensive backup plan to ensure data integrity and system reliability.

## ⚠️ Disclaimer

This repository is an archive of a school project and is no longer actively maintained. The scripts and configurations provided are for educational purposes only and may not be suitable for production environments.

Also, the script organization has been changed for easier access. However, please note that these changes have not been tested.

## 👥 Contributors

- **Ika** - *Initial work* - [Ika's GitHub](https://github.com/Ika-02)
- **Pronyx** - *Backups* - [Pronyx's GitHub](https://github.com/YameteNekoSan)