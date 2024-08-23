
This package contains the installer for ST-LINK-SERVER software module.

To install ST-LINK-SERVER for Windows on your system use the st-stlink-server.xxxx.msi installer.

To install ST-LINK-SERVER for MACOS on your system use the st-stlink-server.xxxx.pkg installer.


To install ST-LINK-SERVER for Linux on your system use one of the package provided.
The package to use depends on your machine distribution but also on your system knowledge.

    * RPM-based distribution (Redhat, Centos, Suse, Fedora...)
        As root user:
        - either run: sudo rpm -Uhv st-stlink-server-xxxx-linux-amd64.rpm
        - or use the dedicated software package manager from your system

    * Debian-based distribution (Debian, Ubuntu...)
        As root user:
        - either run: sudo dpkg -i st-stlink-server-xxxx-linux-amd64.deb
        - or use the dedicated software package manager from your system

    * Any/other distribution (but prefer one of the native method above if you can)
        As root user
        - run: sudo sh st-stlink-server.xxxx-linux-amd64.install.sh
