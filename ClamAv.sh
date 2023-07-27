#!/bin/bash

# Fonction pour détecter le système d'exploitation et le gestionnaire de paquets
detect_package_manager() {
    if command -v yum &>/dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v apt-get &>/dev/null; then
        PACKAGE_MANAGER="apt-get"
    elif command -v dnf &>/dev/null; then
        PACKAGE_MANAGER="dnf"
    else
        echo "Gestionnaire de paquets non détecté (apt, yum ou dnf). Impossible de continuer."
        exit 1
    fi
}

# Fonction pour installer ClamAV
install_clamav() {
    if [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo yum update -y
        sudo yum install -y epel-release
        sudo yum -y install clamav clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd
        sudo systemctl stop clamav-freshclam
        sudo freshclam
        sudo systemctl start clamav-freshclam
        # Configure freshclam for automatic updates
        sudo sed -i 's/^Checks/#Checks/' /etc/freshclam.conf
        sudo sed -i 's/^#Checks 24/Checks 288/' /etc/freshclam.conf
        # Adds cronjob to update freshclam every 5 hours
        #(crontab -l ; echo "0 */5 * * * sudo systemctl stop clamav-freshclam && sudo freshclam && sudo systemctl start clamav-freshclam") | crontab -
        #enable clamav-freshclam.service
        systemctl enable clamav-freshclam.service
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo apt-get update -y && sudo apt-get upgrade -y 
        sudo apt-get install -y clamav clamav-daemon 
        sudo systemctl stop clamav-freshclam
        sudo freshclam
        sudo systemctl start clamav-freshclam
        # Configure freshclam for automatic updates
        sudo sed -i 's/^Checks/#Checks/' /etc/clamav/freshclam.conf
        sudo sed -i 's/^#Checks 24/Checks 288/' /etc/clamav/freshclam.conf
        # Adds cronjob to update freshclam every 5 hours
        #(crontab -l ; echo "0 */5 * * * sudo systemctl stop clamav-freshclam && sudo freshclam && sudo systemctl start clamav-freshclam") | crontab -
        #enable clamav-freshclam.service
        systemctl enable clamav-freshclam.service
    fi
}   

# Fonction pour configurer ClamAV
configure_clamav_obsolete() {
    # Configurer ClamAV
    if [ "$PACKAGE_MANAGER" == "yum" ] || [ "$PACKAGE_MANAGER" == "dnf" ]; then
        sudo sed -i 's/^Example/#Example/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#LocalSocket/LocalSocket/' /etc/clamd.d/scan.conf
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo sed -i 's/^Example/#Example/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#LocalSocket/LocalSocket/' /etc/clamav/clamd.conf
    fi
    # Redémarrer le service ClamAV
    if [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo systemctl start clamav-freshclam
        sudo systemctl start clamav
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo systemctl start clamav-freshclam
        sudo systemctl start clamav-daemon
    fi
}

# Fonction pour configurer ClamAV
configure_clamav() {
    # Configurer ClamAV
    if [ "$PACKAGE_MANAGER" == "yum" ] || [ "$PACKAGE_MANAGER" == "dnf" ]; then
        cp /usr/share/doc/clamav-daemon/examples/clamd.conf.sample /etc/clamd.d/scan.conf
        sudo sed -i 's/^Example/#Example/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#Logfile/LogFile/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#LocalSocket/LocalSocket/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#TCPSocket/TCPSocket/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#TCPAddr/TCPAddr/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#OnAccessPrevention/OnAccessPrevention/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#OnAccessExcludeUname/OnAccessExcludeUname/' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#OnAccessIncludePath \/home/OnAccessIncludePath \//' /etc/clamd.d/scan.conf
        sudo sed -i 's/^#OnAccessExtraScanning/OnAccessExtraScanning/' /etc/clamd.d/scan.conf 
        sudo chmod 660 /var/run/clamav/clamd.ctl
        #sudo sed -i 's/^#TestDatabases/TestDatabases/' /etc/clamd.d/scan.conf 
        #create quarantine directory if it doesn't exist
        if [ ! -d "/home/quarantine" ]; then
        mkdir /home/quarantine
        fi
        # Configure clamd for automatic scans
        (crontab -l 2>/dev/null; echo "0 */5 * * * clamscan -r --bell -i /home --move=/home/quarantine --exclude-dir=/home/quarantine -l /home/clamav.log") | crontab -
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        cp /usr/share/doc/clamav-daemon/examples/clamd.conf.sample /etc/clamav/clamd.conf
        sudo sed -i 's/^Example/#Example/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#LogFile/LogFile/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#LocalSocket/LocalSocket/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#TCPSocket/TCPSocket/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#TCPAddr/TCPAddr/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#OnAccessPrevention/OnAccessPrevention/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#OnAccessExcludeUname/OnAccessExcludeUname/' /etc/clamav/clamd.conf
        sudo sed -i 's/^#OnAccessIncludePath \/home/OnAccessIncludePath \//' /etc/clamav/clamd.conf   
        sudo sed -i 's/^#OnAccessExtraScanning/OnAccessExtraScanning/' /etc/clamav/clamd.conf 
        sudo chmod 660 /var/run/clamav/clamd.ctl
        #sudo sed -i 's/^#TestDatabases/TestDatabases/' /etc/clamav/clamd.conf   
        #create quarantine directory if it doesn't exist
        if [ ! -d "/home/quarantine" ]; then
        mkdir /home/quarantine
        fi
        # Configure clamd for automatic scans
        (crontab -l 2>/dev/null; echo "0 */5 * * * clamscan -r --bell -i /home --move=/home/quarantine --exclude-dir=/home/quarantine -l /home/clamav.log") | crontab -
    fi
    # restart clamd service
    if [ "$PACKAGE_MANAGER" == "yum" ]; then
        sudo systemctl start clamav-freshclam
        sudo systemctl start clamav
    elif [ "$PACKAGE_MANAGER" == "apt-get" ]; then
        sudo systemctl start clamav-freshclam
        sudo systemctl start clamav-daemon
    fi
}

# Verify if the user is root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# detect package manager
detect_package_manager

# Install ClamAV
install_clamav

# Configure ClamAV
configure_clamav

echo "ClamAv installed successfully!"