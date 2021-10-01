#!/bin/bash

# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

# Last update: Rogier Dijkman (@DijkmanRogier)
# Data       : 9/29/2021
# Info source: https://blog.aelterman.com/about/ (@svenaelterman)

# *********** log tagging variables ***********
INFO_TAG="[INSTALLATION-INFO]"
ERROR_TAG="[INSTALLATION-ERROR]"

# *********** Set Log File ***************
LOGFILE="/var/log/FW-SETUP.log"
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

# *********** help function ***************
usage(){
    echo " "
    echo "Usage: $0 [option...]" >&2
    echo
    echo "   -w         Azure Sentinel Workspace ID"
    echo "   -k         Azure Sentinel Workspace Key"
    echo
    echo "Examples:"
    echo " $0 -w xxxxx -k xxxxxx"
    echo " "
    exit 1
}

# ************ Command Options **********************
while getopts w:k:h option
do
    case "${option}"
    in
        w) WORKSPACE_ID=$OPTARG;;
        k) WORKSPACE_KEY=$OPTARG;;
        h) usage;;
        \?) usage;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

if ((OPTIND == 1))
then
    echo "$ERROR_TAG No options specified"
    usage
fi

############################
# Configure CEF Forwarding #
############################
echo "CONFIGURE CEF FORWARDING"
sudo alternatives --set python /usr/bin/python3
sudo setenforce 0
sudo wget -O cef_installer.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF/cef_installer.py && sudo python cef_installer.py $WORKSPACE_ID $WORKSPACE_KEY
sleep 15

######################
# Configure Firewall #
######################
echo "CONFIGURE LOCAL FIREWALL"
sudo firewall-cmd --direct --permanent --add-rule ipv4 filter INPUT 0 -p tcp --dport 25226 -j ACCEPT
sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --permanent --add-port=514/udp
sudo firewall-cmd --reload
sudo firewall-cmd --direct --get-rules ipv4 filter INPUT

######################################################
# Host Name Setting and Keep Time Generated Original #
######################################################

echo "CONFIGURE HOSTNAME SETTING"
sudo sed -i -e "/'Severity' => tags[tags.size - 1]/ a \ \t 'Host' => record['host']" -e "s/'Severity' => tags[tags.size - 1]/&,/" /opt/microsoft/omsagent/plugin/filter_syslog_security.rb && sudo /opt/microsoft/omsagent/bin/service_control restart $WORKSPACE_ID

echo "CONFIGURE LOG TIME SETTINGS"
sudo wget -O TimeGenerated.py https://raw.githubusercontent.com/Azure/Azure-Sentinel/master/DataConnectors/CEF/TimeGenerated.py && yes | python TimeGenerated.py $WORKSPACE_ID

##############################################
# Re-Enabling and Configuring SELinux Policy #
#############################################

echo "WRAPPING UP INSTALLATION"
sudo setenforce 1
sudo systemctl restart rsyslog.service
sudo ausearch -c 'rsyslogd' --raw | audit2allow -M my-rsyslogd
sudo semodule -X 300 -i my-rsyslogd.pp
sleep 15
sudo systemctl restart rsyslog.service
sudo semanage port -a -t syslogd_port_t -p tcp 25226
systemctl status rsyslog.service

###########################
# SEND SAMPLE CEF MESSAGE #
###########################
sudo wget -O cef_simulator.py https://raw.githubusercontent.com/OTRF/Blacksmith/master/templates/azure/CEF-Log-Analytics-Agent/scripts/cef_simulator.py && sudo python cef_simulator.py --debug
