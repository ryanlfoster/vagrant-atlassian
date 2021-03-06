#!/bin/bash
# ==================================================================================================
# Script to download and install Atlassian JIRA
#
# See also
#	https://maxlab.polito.it/confluence/x/DAAb
# ==================================================================================================

DOWNLOAD_DIR="$PWD/tmp"

JIRA_INSTALLFILE="atlassian-jira-6.3.15-x64.bin"
JIRA_BACKUP="2014-Aug-04--1041.zip"

set -e

if [ `whoami` != root ]; then
    SUDO=sudo
else
    SUDO=""
fi

# Install dependencies for Atlassian JIRA
# (none identified so far)

mkdir -p ${DOWNLOAD_DIR}
cd ${DOWNLOAD_DIR}

[ ! -z "${JIRA_INSTALLFILE}" ] && if [ ! -e ${JIRA_INSTALLFILE} ]; then
    echo "INFO: Downloading ${JIRA_INSTALLFILE}"
    wget http://www.atlassian.com/software/jira/downloads/binary/${JIRA_INSTALLFILE}
    chmod 755 ${JIRA_INSTALLFILE}
fi

cd -

echo "INFO: Installing ${JIRA_INSTALLFILE}"
${SUDO} ${DOWNLOAD_DIR}/${JIRA_INSTALLFILE} <<__END__
o
2
/opt/atlassian/jira
/var/atlassian/application-data/jira
1
y
__END__

# Ensure that JIRA is automatically restarted even if running inside
# Docker container gmacario/baseimage:0.9.15 (where `/sbin/my_init` runs as PID 1)
echo "INFO: Installing /etc/service/jira/run"
cat >/tmp/run <<__END__
#!/bin/sh
set -e
cd "/opt/atlassian/jira/bin"
exec ./start-jira.sh -fg
__END__
${SUDO} install -m 755 -d /etc/service/jira/
${SUDO} install -m 755 /tmp/run /etc/service/jira/

if [ ! -z "${JIRA_BACKUP}" ]; then
    echo "INFO: Preparing restore of ${JIRA_BACKUP}..."
    ${SUDO} mkdir -p /var/atlassian/application-data/jira/import
    ${SUDO} chown jira /var/atlassian/application-data/jira/import
    ${SUDO} cp ${DOWNLOAD_DIR}/${JIRA_BACKUP} /var/atlassian/application-data/jira/import/
fi

# END
