#!/bin/bash
set -e
#set -x

# Green & Red marking for Success and Failed messages
SUCCESS='\033[0;32m'
FAILED='\033[0;31;1m'
NC='\033[0m'

# IP addresses
PRIMARY_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
CONTROL01=$(dig +short controlplane01)
CONTROL02=$(dig +short controlplane02)
NODE01=$(dig +short node01)
NODE02=$(dig +short node02)
LOADBALANCER=$(dig +short loadbalancer)
LOCALHOST="127.0.0.1"

# All Cert Location
# ca certificate location
CACERT=ca.crt
CAKEY=ca.key

# Kube controller manager certificate location
KCMCERT=kube-controller-manager.crt
KCMKEY=kube-controller-manager.key

# Kube proxy certificate location
KPCERT=kube-proxy.crt
KPKEY=kube-proxy.key

# Kube scheduler certificate location
KSCERT=kube-scheduler.crt
KSKEY=kube-scheduler.key

# Kube api certificate location
APICERT=kube-apiserver.crt
APIKEY=kube-apiserver.key

# ETCD certificate location
ETCDCERT=etcd-server.crt
ETCDKEY=etcd-server.key

# Service account certificate location
SACERT=service-account.crt
SAKEY=service-account.key

# All kubeconfig locations

# kubeproxy.kubeconfig location
KPKUBECONFIG=kube-proxy.kubeconfig

# kube-controller-manager.kubeconfig location
KCMKUBECONFIG=kube-controller-manager.kubeconfig

# kube-scheduler.kubeconfig location
KSKUBECONFIG=kube-scheduler.kubeconfig

# admin.kubeconfig location
ADMINKUBECONFIG=admin.kubeconfig

# All systemd service locations

# etcd systemd service
SYSTEMD_ETCD_FILE=/etc/systemd/system/etcd.service

# kub-api systemd service
SYSTEMD_API_FILE=/etc/systemd/system/kube-apiserver.service

# kube-controller-manager systemd service
SYSTEMD_KCM_FILE=/etc/systemd/system/kube-controller-manager.service

# kube-scheduler systemd service
SYSTEMD_KS_FILE=/etc/systemd/system/kube-scheduler.service

### WORKER NODES ###

# Worker-1 cert details
NODE01_CERT=/var/lib/kubelet/node01.crt
NODE01_KEY=/var/lib/kubelet/node01.key

# Worker-1 kubeconfig location
NODE01_KUBECONFIG=/var/lib/kubelet/kubeconfig

# Worker-1 kubelet config location
NODE01_KUBELET=/var/lib/kubelet/kubelet-config.yaml

# Systemd node01 kubelet location
SYSTEMD_NODE01_KUBELET=/etc/systemd/system/kubelet.service

# kube-proxy node01 location
NODE01_KP_KUBECONFIG=/var/lib/kube-proxy/kubeconfig
SYSTEMD_NODE01_KP=/etc/systemd/system/kube-proxy.service


# Function - Master node #

check_cert_and_key()
{
    local name=$1
    local subject=$2
    local issuer=$3
    local nokey=
    local cert="${CERT_LOCATION}/$1.crt"
    local key="${CERT_LOCATION}/$1.key"

    if [ -z $cert -o -z $key ]
        then
            printf "${FAILED}cert and/or key not present in ${CERT_LOCATION}. Perhaps you missed a copy step\n${NC}"
            exit 1
        elif [ -f $cert -a -f $key ]
            then
                printf "${NC}${name} cert and key found, verifying the authenticity\n"
                CERT_SUBJECT=$(sudo openssl x509 -in $cert -text | grep "Subject: CN"| tr -d " ")
                CERT_ISSUER=$(sudo openssl x509 -in $cert -text | grep "Issuer: CN"| tr -d " ")
                CERT_MD5=$(sudo openssl x509 -noout -modulus -in $cert | openssl md5| awk '{print $2}')
                KEY_MD5=$(sudo openssl rsa -noout -modulus -in $key | openssl md5| awk '{print $2}')
                if [ $CERT_SUBJECT == "${subject}" ] && [ $CERT_ISSUER == "${issuer}" ] && [ $CERT_MD5 == $KEY_MD5 ]
                    then
                        printf "${SUCCESS}${name} cert and key are correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ${name} certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n${NC}"
                        exit 1
                fi
            else
                printf "${FAILED}${cert} / ${key} is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n"
                echo "These should be in /var/lib/kubernetes/pki (most certs), /etc/etcd (eccd server certs) or /var/lib/kubelet (kubelet certs)${NC}"
                exit 1
    fi
}

check_cert_only()
{
    local name=$1
    local subject=$2
    local issuer=$3
    local cert="${CERT_LOCATION}/$1.crt"

    # Worker-2 auto cert is a .pem
    [ -f "${CERT_LOCATION}/$1.pem" ] && cert="${CERT_LOCATION}/$1.pem"

    if [ -z $cert ]
        then
            printf "${FAILED}cert not present in ${CERT_LOCATION}. Perhaps you missed a copy step\n${NC}"
            exit 1
        elif [ -f $cert ]
            then
                printf "${NC}${name} cert found, verifying the authenticity\n"
                CERT_SUBJECT=$(sudo openssl x509 -in $cert -text | grep "Subject: "| tr -d " ")
                CERT_ISSUER=$(sudo openssl x509 -in $cert -text | grep "Issuer: CN"| tr -d " ")
                CERT_MD5=$(sudo openssl x509 -noout -modulus -in $cert | openssl md5| awk '{print $2}')
                if [ $CERT_SUBJECT == "${subject}" ] && [ $CERT_ISSUER == "${issuer}" ]
                    then
                        printf "${SUCCESS}${name} cert is correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ${name} certificate, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n${NC}"
                        exit 1
                fi
            else
                if [[ $cert == *kubelet-client-current* ]]
                then
                    printf "${FAILED}${cert} missing. This probably means that kubelet failed to start.${NC}\n"
                    echo -e "Check logs with\n\n  sudo journalctl -u kubelet\n"
                else
                    printf "${FAILED}${cert} missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n${NC}"
                    echo "These should be in ${CERT_LOCATION}"
                fi
                exit 1
    fi
}

check_cert_adminkubeconfig()
{
    if [ -z $ADMINKUBECONFIG ]
        then
            printf "${FAILED}please specify admin kubeconfig location\n${NC}"
            exit 1
        elif [ -f $ADMINKUBECONFIG ]
            then
                printf "${NC}admin kubeconfig file found, verifying the authenticity\n"
                ADMINKUBECONFIG_SUBJECT=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | sudo openssl x509 -text | grep "Subject: CN" | tr -d " ")
                ADMINKUBECONFIG_ISSUER=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | sudo openssl x509 -text | grep "Issuer: CN" | tr -d " ")
                ADMINKUBECONFIG_CERT_MD5=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | sudo openssl x509 -noout | openssl md5 | awk '{print $2}')
                ADMINKUBECONFIG_KEY_MD5=$(cat $ADMINKUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                ADMINKUBECONFIG_SERVER=$(cat $ADMINKUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $ADMINKUBECONFIG_SUBJECT == "Subject:CN=admin,O=system:masters" ] && [ $ADMINKUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA,O=Kubernetes" ] && [ $ADMINKUBECONFIG_CERT_MD5 == $ADMINKUBECONFIG_KEY_MD5 ] && [ $ADMINKUBECONFIG_SERVER == "https://127.0.0.1:6443" ]
                    then
                        printf "${SUCCESS}admin kubeconfig cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the admin kubeconfig certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-admin-kubernetes-configuration-file\n"
                        exit 1
                fi
            else
                printf "${FAILED}admin kubeconfig file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-admin-kubernetes-configuration-file\n"
                exit 1
    fi
}


get_kubeconfig_cert_path()
{
    local kubeconfig=$1
    local cert_field=$2

    sudo cat $kubeconfig | grep cert_field | awk '{print $2}'
}

check_kubeconfig()
{
    local name=$1
    local location=$2
    local apiserver=$3
    local kubeconfig="${location}/${name}.kubeconfig"

    echo "Checking $kubeconfig"
    check_kubeconfig_exists $name $location
    ca=$(get_kubeconfig_cert_path $kubeconfig "certificate-authority")
    cert=$(get_kubeconfig_cert_path $kubeconfig "client-certificate")
    key=$(get_kubeconfig_cert_path $kubeconfig "client-key")
    server=$(sudo cat $kubeconfig | grep server | awk '{print $2}')

    if [ -f "$ca"]
    then
        printf "${SUCCESS}Path to CA certificate is correct${NC}\n"
    else
        printf "${FAIL}CA certificate not found at ${ca}${NC}\n"
        exit 1
    fi

    if [ -f "$cert"]
    then
        printf "${SUCCESS}Path to client certificate is correct${NC}\n"
    else
        printf "${FAIL}Client certificate not found at ${cert}${NC}\n"
        exit 1
    fi

    if [ -f "$key"]
    then
        printf "${SUCCESS}Path to client key is correct${NC}\n"
    else
        printf "${FAIL}Client key not found at ${key}${NC}\n"
        exit 1
    fi

    if [ "$apiserver" = "$server" ]
    then
        printf "${SUCCESS}Server URL is correct${NC}\n"
    else
        printf "${FAIL}Server URL ${server} is incorrect${NC}\n"
        exit 1
    fi
}

check_kubeconfig_exists() {
    local name=$1
    local location=$2
    local kubeconfig="${location}/${name}.kubeconfig"

    if [ -f "${kubeconfig}" ]
    then
        printf "${SUCCESS}${kubeconfig} found${NC}\n"
    else
        printf "${FAIL}${kubeconfig} not found!${NC}\n"
        exit 1
    fi
}

check_systemd_etcd()
{
    if [ -z $ETCDCERT ] && [ -z $ETCDKEY ]
        then
            printf "${FAILED}please specify ETCD cert and key location, Exiting....\n${NC}"
            exit 1
        elif [ -f $SYSTEMD_ETCD_FILE ]
            then
                printf "${NC}Systemd for ETCD service found, verifying the authenticity\n"

                # Systemd cert and key file details
                ETCD_CA_CERT=ca.crt
                CERT_FILE=$(systemctl cat etcd.service | grep "\--cert-file"| awk '{print $1}'| cut -d "=" -f2)
                KEY_FILE=$(systemctl cat etcd.service | grep "\--key-file"| awk '{print $1}' | cut -d "=" -f2)
                PEER_CERT_FILE=$(systemctl cat etcd.service | grep "\--peer-cert-file"| awk '{print $1}'| cut -d "=" -f2)
                PEER_KEY_FILE=$(systemctl cat etcd.service | grep "\--peer-key-file"| awk '{print $1}'| cut -d "=" -f2)
                TRUSTED_CA_FILE=$(systemctl cat etcd.service | grep "\--trusted-ca-file"| awk '{print $1}'| cut -d "=" -f2)
                PEER_TRUSTED_CA_FILE=$(systemctl cat etcd.service | grep "\--peer-trusted-ca-file"| awk '{print $1}'| cut -d "=" -f2)

                # Systemd advertise , client and peer url's

                IAP_URL=$(systemctl cat etcd.service | grep "\--initial-advertise-peer-urls"| awk '{print $2}')
                LP_URL=$(systemctl cat etcd.service | grep "\--listen-peer-urls"| awk '{print $2}')
                LC_URL=$(systemctl cat etcd.service | grep "\--listen-client-urls"| awk '{print $2}')
                AC_URL=$(systemctl cat etcd.service | grep "\--advertise-client-urls"| awk '{print $2}')


                   ETCD_CA_CERT=/etc/etcd/ca.crt
                   ETCDCERT=/etc/etcd/etcd-server.crt
                   ETCDKEY=/etc/etcd/etcd-server.key
                if [ $CERT_FILE == $ETCDCERT ] && [ $KEY_FILE == $ETCDKEY ] && [ $PEER_CERT_FILE == $ETCDCERT ] && [ $PEER_KEY_FILE == $ETCDKEY ] && \
                   [ $TRUSTED_CA_FILE == $ETCD_CA_CERT ] && [ $PEER_TRUSTED_CA_FILE = $ETCD_CA_CERT ]
                    then
                        printf "${SUCCESS}ETCD certificate, ca and key files are correct under systemd service\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ETCD certificate, ca and keys. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n${NC}"
                        exit 1
                fi

                if [ $IAP_URL == "https://$PRIMARY_IP:2380" ] && [ $LP_URL == "https://$PRIMARY_IP:2380"  ] && [ $LC_URL == "https://$PRIMARY_IP:2379,https://127.0.0.1:2379" ] && \
                   [ $AC_URL == "https://$PRIMARY_IP:2379" ]
                    then
                        printf "${SUCCESS}ETCD initial-advertise-peer-urls, listen-peer-urls, listen-client-urls, advertise-client-urls are correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ETCD initial-advertise-peer-urls / listen-peer-urls / listen-client-urls / advertise-client-urls. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n${NC}"
                        exit 1
                fi

            else
                printf "${FAILED}etcd-server.crt / etcd-server.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n${NC}"
                exit 1
    fi
}

check_systemd_api()
{
    if [ -z $APICERT ] && [ -z $APIKEY ]
        then
            printf "${FAILED}please specify kube-api cert and key location, Exiting....\n${NC}"
            exit 1
        elif [ -f $SYSTEMD_API_FILE ]
            then
                printf "Systemd for kube-api service found, verifying the authenticity\n"

                ADVERTISE_ADDRESS=$(systemctl cat kube-apiserver.service | grep "\--advertise-address" | awk '{print $1}' | cut -d "=" -f2)
                CLIENT_CA_FILE=$(systemctl cat kube-apiserver.service | grep "\--client-ca-file" | awk '{print $1}' | cut -d "=" -f2)
                ETCD_CA_FILE=$(systemctl cat kube-apiserver.service | grep "\--etcd-cafile" | awk '{print $1}' | cut -d "=" -f2)
                ETCD_CERT_FILE=$(systemctl cat kube-apiserver.service | grep "\--etcd-certfile" | awk '{print $1}' | cut -d "=" -f2)
                ETCD_KEY_FILE=$(systemctl cat kube-apiserver.service | grep "\--etcd-keyfile" | awk '{print $1}' | cut -d "=" -f2)
                KUBELET_CERTIFICATE_AUTHORITY=$(systemctl cat kube-apiserver.service | grep "\--kubelet-certificate-authority" | awk '{print $1}' | cut -d "=" -f2)
                KUBELET_CLIENT_CERTIFICATE=$(systemctl cat kube-apiserver.service | grep "\--kubelet-client-certificate" | awk '{print $1}' | cut -d "=" -f2)
                KUBELET_CLIENT_KEY=$(systemctl cat kube-apiserver.service | grep "\--kubelet-client-key" | awk '{print $1}' | cut -d "=" -f2)
                SERVICE_ACCOUNT_KEY_FILE=$(systemctl cat kube-apiserver.service | grep "\--service-account-key-file" | awk '{print $1}' | cut -d "=" -f2)
                TLS_CERT_FILE=$(systemctl cat kube-apiserver.service | grep "\--tls-cert-file" | awk '{print $1}' | cut -d "=" -f2)
                TLS_PRIVATE_KEY_FILE=$(systemctl cat kube-apiserver.service | grep "\--tls-private-key-file" | awk '{print $1}' | cut -d "=" -f2)

                PKI=/var/lib/kubernetes/pki
                CACERT="${PKI}/ca.crt"
                APICERT="${PKI}/kube-apiserver.crt"
                APIKEY="${PKI}/kube-apiserver.key"
                SACERT="${PKI}/service-account.crt"
                KCCERT="${PKI}/apiserver-kubelet-client.crt"
                KCKEY="${PKI}/apiserver-kubelet-client.key"
                if [ $ADVERTISE_ADDRESS == $PRIMARY_IP ] && [ $CLIENT_CA_FILE == $CACERT ] && [ $ETCD_CA_FILE == $CACERT ] && \
                   [ $ETCD_CERT_FILE == "${PKI}/etcd-server.crt" ] && [ $ETCD_KEY_FILE == "${PKI}/etcd-server.key" ] && \
                   [ $KUBELET_CERTIFICATE_AUTHORITY == $CACERT ] && [ $KUBELET_CLIENT_CERTIFICATE == $KCCERT ] && [ $KUBELET_CLIENT_KEY == $KCKEY ] && \
                   [ $SERVICE_ACCOUNT_KEY_FILE == $SACERT ] && [ $TLS_CERT_FILE == $APICERT ] && [ $TLS_PRIVATE_KEY_FILE == $APIKEY ]
                    then
                        printf "${SUCCESS}kube-apiserver advertise-address/ client-ca-file/ etcd-cafile/ etcd-certfile/ etcd-keyfile/ kubelet-certificate-authority/ kubelet-client-certificate/ kubelet-client-key/ service-account-key-file/ tls-cert-file/ tls-private-key-file are correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-apiserver systemd file, check advertise-address/ client-ca-file/ etcd-cafile/ etcd-certfile/ etcd-keyfile/ kubelet-certificate-authority/ kubelet-client-certificate/ kubelet-client-key/ service-account-key-file/ tls-cert-file/ tls-private-key-file. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server\n${NC}"
                        exit 1
                fi
            else
                printf "${FAILED}kube-apiserver.crt / kube-apiserver.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server\n${NC}"
                exit 1
    fi
}

check_systemd_kcm()
{
    KCMCERT=/var/lib/kubernetes/pki/kube-controller-manager.crt
    KCMKEY=/var/lib/kubernetes/pki/kube-controller-manager.key
    CACERT=/var/lib/kubernetes/pki/ca.crt
    CAKEY=/var/lib/kubernetes/pki/ca.key
    SAKEY=/var/lib/kubernetes/pki/service-account.key
    KCMKUBECONFIG=/var/lib/kubernetes/kube-controller-manager.kubeconfig
    if [ -z $KCMCERT ] && [ -z $KCMKEY ]
        then
            printf "${FAILED}please specify cert and key location\n${NC}"
            exit 1
        elif [ -f $SYSTEMD_KCM_FILE ]
            then
                printf "Systemd for kube-controller-manager service found, verifying the authenticity\n"
                CLUSTER_SIGNING_CERT_FILE=$(systemctl cat kube-controller-manager.service | grep "\--cluster-signing-cert-file" | awk '{print $1}' | cut -d "=" -f2)
                CLUSTER_SIGNING_KEY_FILE=$(systemctl cat kube-controller-manager.service | grep "\--cluster-signing-key-file" | awk '{print $1}' | cut -d "=" -f2)
                KUBECONFIG=$(systemctl cat kube-controller-manager.service | grep "\--kubeconfig" | awk '{print $1}' | cut -d "=" -f2)
                ROOT_CA_FILE=$(systemctl cat kube-controller-manager.service | grep "\--root-ca-file" | awk '{print $1}' | cut -d "=" -f2)
                SERVICE_ACCOUNT_PRIVATE_KEY_FILE=$(systemctl cat kube-controller-manager.service | grep "\--service-account-private-key-file" | awk '{print $1}' | cut -d "=" -f2)

                if [ $CLUSTER_SIGNING_CERT_FILE == $CACERT ] && [ $CLUSTER_SIGNING_KEY_FILE == $CAKEY ] && [ $KUBECONFIG == $KCMKUBECONFIG ] && \
                   [ $ROOT_CA_FILE == $CACERT ] && [ $SERVICE_ACCOUNT_PRIVATE_KEY_FILE == $SAKEY ]
                    then
                        printf "${SUCCESS}kube-controller-manager cluster-signing-cert-file, cluster-signing-key-file, kubeconfig, root-ca-file, service-account-private-key-file  are correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-controller-manager cluster-signing-cert-file, cluster-signing-key-file, kubeconfig, root-ca-file, service-account-private-key-file. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager\n${NC}"
                        exit 1
                fi
            else
                printf "${FAILED}kube-controller-manager.crt / kube-controller-manager.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager\n${NC}"
                exit 1
    fi
}

check_systemd_ks()
{
    KSCERT=/var/lib/kubernetes/pki/kube-scheduler.crt
    KSKEY=/var/lib/kubernetes/pki/kube-scheduler.key
    KSKUBECONFIG=/var/lib/kubernetes/kube-scheduler.kubeconfig

    if [ -z $KSCERT ] && [ -z $KSKEY ]
        then
            printf "${FAILED}please specify cert and key location\n${NC}"
            exit 1
        elif [ -f $SYSTEMD_KS_FILE ]
            then
                printf "Systemd for kube-scheduler service found, verifying the authenticity\n"

                KUBECONFIG=$(systemctl cat kube-scheduler.service | grep "\--kubeconfig"| awk '{print $1}'| cut -d "=" -f2)

                if [ $KUBECONFIG == $KSKUBECONFIG ]
                    then
                        printf "${SUCCESS}kube-scheduler --kubeconfig is correct\n${NC}"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-scheduler --kubeconfig. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler\n${NC}"
                        exit 1
                fi
            else
                printf "${FAILED}kube-scheduler.crt / kube-scheduler.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler\n${NC}"
                exit 1
    fi
}

# END OF Function - Master node #

if [ ! -z "$1" ]
then
    choice=$1
else
    echo "This script will validate the certificates in master as well as node01 nodes. Before proceeding, make sure you ssh into the respective node [ Master or Worker-1 ] for certificate validation"
    while true
    do
        echo
        echo "  1. Verify certificates on Master Nodes after step 4"
        echo "  2. Verify kubeconfigs on Master Nodes after step 5"
        echo "  3. Verify kubeconfigs and PKI on Master Nodes after step 8"
        echo "  4. Verify kubeconfigs and PKI on node01 Node after step 10"
        echo "  5. Verify kubeconfigs and PKI on node02 Node after step 11"
        echo
        echo -n "Please select one of the above options: "
        read choice

        [ -z "$choice" ] && continue
        [ $choice -gt 0 -a $choice -lt 6 ] && break
    done
fi

HOST=$(hostname -s)

CERT_ISSUER="Issuer:CN=KUBERNETES-CA,O=Kubernetes"
SUBJ_CA="Subject:CN=KUBERNETES-CA,O=Kubernetes"
SUBJ_ADMIN="Subject:CN=admin,O=system:masters"
SUBJ_KCM="Subject:CN=system:kube-controller-manager,O=system:kube-controller-manager"
SUBJ_KP="Subject:CN=system:kube-proxy,O=system:node-proxier"
SUBJ_KS="Subject:CN=system:kube-scheduler,O=system:kube-scheduler"
SUBJ_API="Subject:CN=kube-apiserver,O=Kubernetes"
SUBJ_SA="Subject:CN=service-accounts,O=Kubernetes"
SUBJ_ETCD="Subject:CN=etcd-server,O=Kubernetes"
SUBJ_APIKC="Subject:CN=kube-apiserver-kubelet-client,O=system:masters"

case $choice in

  1)
    if ! [ "${HOST}" = "controlplane01" -o "${HOST}" = "controlplane02" ]
    then
        printf "${FAILED}Must run on controlplane01 or controlplane02${NC}\n"
        exit 1
    fi

    echo -e "The selected option is $choice, proceeding the certificate verification of Master node"

    CERT_LOCATION=$HOME
    check_cert_and_key "ca" $SUBJ_CA $CERT_ISSUER
    check_cert_and_key "kube-apiserver" $SUBJ_API $CERT_ISSUER
    check_cert_and_key "kube-controller-manager" $SUBJ_KCM $CERT_ISSUER
    check_cert_and_key "kube-scheduler" $SUBJ_KS $CERT_ISSUER
    check_cert_and_key "service-account" $SUBJ_SA $CERT_ISSUER
    check_cert_and_key "apiserver-kubelet-client" $SUBJ_APIKC $CERT_ISSUER
    check_cert_and_key "etcd-server" $SUBJ_ETCD $CERT_ISSUER

    if [ "${HOST}" = "controlplane01" ]
    then
        check_cert_and_key "admin" $SUBJ_ADMIN $CERT_ISSUER
        check_cert_and_key "kube-proxy" $SUBJ_KP $CERT_ISSUER
    fi
    ;;

  2)
    if ! [ "${HOST}" = "controlplane01" -o "${HOST}" = "controlplane02" ]
    then
        printf "${FAILED}Must run on controlplane01 or controlplane02${NC}\n"
        exit 1
    fi

    check_cert_adminkubeconfig
    check_kubeconfig_exists "kube-controller-manager" $HOME
    check_kubeconfig_exists "kube-scheduler" $HOME

    if [ "${HOST}" = "controlplane01" ]
    then
        check_kubeconfig_exists "kube-proxy" $HOME
    fi
    ;;

  3)
    if ! [ "${HOST}" = "controlplane01" -o "${HOST}" = "controlplane02" ]
    then
        printf "${FAILED}Must run on controlplane01 or controlplane02${NC}\n"
        exit 1
    fi

    CERT_LOCATION=/etc/etcd
    check_cert_only "ca" $SUBJ_CA $CERT_ISSUER
    check_cert_and_key "etcd-server" $SUBJ_ETCD $CERT_ISSUER

    CERT_LOCATION=/var/lib/kubernetes/pki
    check_cert_and_key "ca" $SUBJ_CA $CERT_ISSUER
    check_cert_and_key "kube-apiserver" $SUBJ_API $CERT_ISSUER
    check_cert_and_key "kube-controller-manager" $SUBJ_KCM $CERT_ISSUER
    check_cert_and_key "kube-scheduler" $SUBJ_KS $CERT_ISSUER
    check_cert_and_key "service-account" $SUBJ_SA $CERT_ISSUER
    check_cert_and_key "apiserver-kubelet-client" $SUBJ_APIKC $CERT_ISSUER
    check_cert_and_key "etcd-server" $SUBJ_ETCD $CERT_ISSUER

    check_kubeconfig "kube-controller-manager" "/var/lib/kubernetes" "https://127.0.0.1:6443"
    check_kubeconfig "kube-scheduler" "/var/lib/kubernetes" "https://127.0.0.1:6443"

    check_systemd_api
    check_systemd_etcd
    check_systemd_kcm
    check_systemd_ks
    ;;

  4)
    if ! [ "${HOST}" = "node01" ]
    then
        printf "${FAILED}Must run on node01${NC}\n"
        exit 1
    fi

    CERT_LOCATION=/var/lib/kubernetes/pki
    check_cert_only "ca" $SUBJ_CA $CERT_ISSUER
    check_cert_and_key "kube-proxy" $SUBJ_KP $CERT_ISSUER
    check_cert_and_key "node01" "Subject:CN=system:node:node01,O=system:nodes" $CERT_ISSUER
    check_kubeconfig "kube-proxy" "/var/lib/kube-proxy" "https://${LOADBALANCER}:6443"
    check_kubeconfig "kubelet" "/var/lib/kubelet" "https://${LOADBALANCER}:6443"
    ;;

  5)
    if ! [ "${HOST}" = "node02" ]
    then
        printf "${FAILED}Must run on node02${NC}\n"
        exit 1
    fi

    CERT_LOCATION=/var/lib/kubernetes/pki
    check_cert_only "ca" $SUBJ_CA $CERT_ISSUER
    check_cert_and_key "kube-proxy" $SUBJ_KP $CERT_ISSUER

    CERT_LOCATION=/var/lib/kubelet/pki
    check_cert_only "kubelet-client-current" "Subject:O=system:nodes,CN=system:node:node02" $CERT_ISSUER
    check_kubeconfig "kube-proxy" "/var/lib/kube-proxy" "https://${LOADBALANCER}:6443"
    ;;


  *)
    printf "${FAILED}Exiting.... Please select the valid option either 1 or 2\n${NC}"
    exit 1
    ;;
esac
