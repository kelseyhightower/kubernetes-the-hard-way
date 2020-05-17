#!/bin/bash
set -e
#set -x

# Green & Red marking for Success and Failed messages
SUCCESS='\033[0;32m'
FAILED='\033[0;31m'
NC='\033[0m'

# All Cert Location

# ca certificate location
CACERT=ca.crt
CAKEY=ca.key

# admin certificate location
ADMINCERT=admin.crt
ADMINKEY=admin.key

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
WORKER_1_CERT=/var/lib/kubelet/worker-1.crt
WORKER_1_KEY=/var/lib/kubelet/worker-1.key

# Worker-1 kubeconfig location
WORKER_1_KUBECONFIG=/var/lib/kubelet/kubeconfig

# Worker-1 kubelet config location
WORKER_1_KUBELET=/var/lib/kubelet/kubelet-config.yaml

# Systemd worker-1 kubelet location
SYSTEMD_WORKER_1_KUBELET=/etc/systemd/system/kubelet.service

# kube-proxy worker-1 location
WORKER_1_KP_KUBECONFIG=/var/lib/kube-proxy/kubeconfig
SYSTEMD_WORKER_1_KP=/etc/systemd/system/kube-proxy.service


# Function - Master node #

check_cert_ca()
{
    if [ -z $CACERT ] && [ -z $CAKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $CACERT ] && [ -f $CAKEY ]
            then
                printf "${NC}CA cert and key found, verifying the authenticity\n"
                CACERT_SUBJECT=$(openssl x509 -in $CACERT -text | grep "Subject: CN"| tr -d " ")
                CACERT_ISSUER=$(openssl x509 -in $CACERT -text | grep "Issuer: CN"| tr -d " ")
                CACERT_MD5=$(openssl x509 -noout -modulus -in $CACERT | openssl md5| awk '{print $2}')
                CAKEY_MD5=$(openssl rsa -noout -modulus -in $CAKEY | openssl md5| awk '{print $2}')
                if [ $CACERT_SUBJECT == "Subject:CN=KUBERNETES-CA" ] && [ $CACERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $CACERT_MD5 == $CAKEY_MD5 ]
                    then
                        printf "${SUCCESS}CA cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the CA certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n"
                        exit 1
                fi
            else
                printf "${FAILED}ca.crt / ca.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#certificate-authority\n"
                exit 1
    fi
}


check_cert_admin()
{
    if [ -z $ADMINCERT ] && [ -z $ADMINKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $ADMINCERT ] && [ -f $ADMINKEY ]
            then
                printf "${NC}admin cert and key found, verifying the authenticity\n"
                ADMINCERT_SUBJECT=$(openssl x509 -in $ADMINCERT -text | grep "Subject: CN"| tr -d " ")
                ADMINCERT_ISSUER=$(openssl x509 -in $ADMINCERT -text | grep "Issuer: CN"| tr -d " ")
                ADMINCERT_MD5=$(openssl x509 -noout -modulus -in $ADMINCERT | openssl md5| awk '{print $2}')
                ADMINKEY_MD5=$(openssl rsa -noout -modulus -in $ADMINKEY | openssl md5| awk '{print $2}')
                if [ $ADMINCERT_SUBJECT == "Subject:CN=admin,O=system:masters" ] && [ $ADMINCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $ADMINCERT_MD5 == $ADMINKEY_MD5 ]
                    then
                        printf "${SUCCESS}admin cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the admin certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-admin-client-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}admin.crt / admin.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-admin-client-certificate\n"
                exit 1
    fi
}

check_cert_kcm()
{
    if [ -z $KCMCERT ] && [ -z $KCMKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $KCMCERT ] && [ -f $KCMKEY ]
            then
                printf "${NC}kube-controller-manager cert and key found, verifying the authenticity\n"
                KCMCERT_SUBJECT=$(openssl x509 -in $KCMCERT -text | grep "Subject: CN"| tr -d " ")
                KCMCERT_ISSUER=$(openssl x509 -in $KCMCERT -text | grep "Issuer: CN"| tr -d " ")
                KCMCERT_MD5=$(openssl x509 -noout -modulus -in $KCMCERT | openssl md5| awk '{print $2}')
                KCMKEY_MD5=$(openssl rsa -noout -modulus -in $KCMKEY | openssl md5| awk '{print $2}')
                if [ $KCMCERT_SUBJECT == "Subject:CN=system:kube-controller-manager" ] && [ $KCMCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KCMCERT_MD5 == $KCMKEY_MD5 ]
                    then
                        printf "${SUCCESS}kube-controller-manager cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-controller-manager certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-controller-manager-client-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-controller-manager.crt / kube-controller-manager.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-controller-manager-client-certificate\n"
                exit 1
    fi
}

check_cert_kp()
{
    if [ -z $KPCERT ] && [ -z $KPKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $KPCERT ] && [ -f $KPKEY ]
            then
                printf "${NC}kube-proxy cert and key found, verifying the authenticity\n"
                KPCERT_SUBJECT=$(openssl x509 -in $KPCERT -text | grep "Subject: CN"| tr -d " ")
                KPCERT_ISSUER=$(openssl x509 -in $KPCERT -text | grep "Issuer: CN"| tr -d " ")
                KPCERT_MD5=$(openssl x509 -noout -modulus -in $KPCERT | openssl md5| awk '{print $2}')
                KPKEY_MD5=$(openssl rsa -noout -modulus -in $KPKEY | openssl md5| awk '{print $2}')
                if [ $KPCERT_SUBJECT == "Subject:CN=system:kube-proxy" ] && [ $KPCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KPCERT_MD5 == $KPKEY_MD5 ]
                    then
                        printf "${SUCCESS}kube-proxy cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-proxy certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kube-proxy-client-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-proxy.crt / kube-proxy.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kube-proxy-client-certificate\n"
                exit 1
    fi
}

check_cert_ks()
{
    if [ -z $KSCERT ] && [ -z $KSKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $KSCERT ] && [ -f $KSKEY ]
            then
                printf "${NC}kube-scheduler cert and key found, verifying the authenticity\n"
                KSCERT_SUBJECT=$(openssl x509 -in $KSCERT -text | grep "Subject: CN"| tr -d " ")
                KSCERT_ISSUER=$(openssl x509 -in $KSCERT -text | grep "Issuer: CN"| tr -d " ")
                KSCERT_MD5=$(openssl x509 -noout -modulus -in $KSCERT | openssl md5| awk '{print $2}')
                KSKEY_MD5=$(openssl rsa -noout -modulus -in $KSKEY | openssl md5| awk '{print $2}')
                if [ $KSCERT_SUBJECT == "Subject:CN=system:kube-scheduler" ] && [ $KSCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KSCERT_MD5 == $KSKEY_MD5 ]
                    then
                        printf "${SUCCESS}kube-scheduler cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-scheduler certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-scheduler-client-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-scheduler.crt / kube-scheduler.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-scheduler-client-certificate\n"
                exit 1
    fi
}

check_cert_api()
{
    if [ -z $APICERT ] && [ -z $APIKEY ]
        then
            printf "${FAILED}please specify kube-api cert and key location, Exiting....\n"
            exit 1
        elif [ -f $APICERT ] && [ -f $APIKEY ]
            then
                printf "${NC}kube-apiserver cert and key found, verifying the authenticity\n"
                APICERT_SUBJECT=$(openssl x509 -in $APICERT -text | grep "Subject: CN"| tr -d " ")
                APICERT_ISSUER=$(openssl x509 -in $APICERT -text | grep "Issuer: CN"| tr -d " ")
                APICERT_MD5=$(openssl x509 -noout -modulus -in $APICERT | openssl md5| awk '{print $2}')
                APIKEY_MD5=$(openssl rsa -noout -modulus -in $APIKEY | openssl md5| awk '{print $2}')
                if [ $APICERT_SUBJECT == "Subject:CN=kube-apiserver" ] && [ $APICERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $APICERT_MD5 == $APIKEY_MD5 ]
                    then
                        printf "${SUCCESS}kube-apiserver cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-apiserver certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubernetes-api-server-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-apiserver.crt / kube-apiserver.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-kubernetes-api-server-certificate\n"
                exit 1
    fi
}

check_cert_etcd()
{
    if [ -z $ETCDCERT ] && [ -z $ETCDKEY ]
        then
            printf "${FAILED}please specify ETCD cert and key location, Exiting....\n"
            exit 1
        elif [ -f $ETCDCERT ] && [ -f $ETCDKEY ]
            then
                printf "${NC}ETCD cert and key found, verifying the authenticity\n"
                ETCDCERT_SUBJECT=$(openssl x509 -in $ETCDCERT -text | grep "Subject: CN"| tr -d " ")
                ETCDCERT_ISSUER=$(openssl x509 -in $ETCDCERT -text | grep "Issuer: CN"| tr -d " ")
                ETCDCERT_MD5=$(openssl x509 -noout -modulus -in $ETCDCERT | openssl md5| awk '{print $2}')
                ETCDKEY_MD5=$(openssl rsa -noout -modulus -in $ETCDKEY | openssl md5| awk '{print $2}')
                if [ $ETCDCERT_SUBJECT == "Subject:CN=etcd-server" ] && [ $ETCDCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $ETCDCERT_MD5 == $ETCDKEY_MD5 ]
                    then
                        printf "${SUCCESS}etcd-server.crt / etcd-server.key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ETCD certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-etcd-server-certificate\n"
                        exit 1
                fi
            else
                printf "${FAILED}etcd-server.crt / etcd-server.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-etcd-server-certificate\n"
                exit 1
    fi
}

check_cert_sa()
{
    if [ -z $SACERT ] && [ -z $SAKEY ]
        then
            printf "${FAILED}please specify Service Account cert and key location, Exiting....\n"
            exit 1
        elif [ -f $SACERT ] && [ -f $SAKEY ]
            then
                printf "${NC}service account cert and key found, verifying the authenticity\n"
                SACERT_SUBJECT=$(openssl x509 -in $SACERT -text | grep "Subject: CN"| tr -d " ")
                SACERT_ISSUER=$(openssl x509 -in $SACERT -text | grep "Issuer: CN"| tr -d " ")
                SACERT_MD5=$(openssl x509 -noout -modulus -in $SACERT | openssl md5| awk '{print $2}')
                SAKEY_MD5=$(openssl rsa -noout -modulus -in $SAKEY | openssl md5| awk '{print $2}')
                if [ $SACERT_SUBJECT == "Subject:CN=service-accounts" ] && [ $SACERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $SACERT_MD5 == $SAKEY_MD5 ]
                    then
                        printf "${SUCCESS}Service Account cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the Service Account certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-service-account-key-pair\n"
                        exit 1
                fi
            else
                printf "${FAILED}service-account.crt / service-account.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/04-certificate-authority.md#the-service-account-key-pair\n"
                exit 1
    fi
}


check_cert_kpkubeconfig()
{
    if [ -z $KPKUBECONFIG ]
        then
            printf "${FAILED}please specify kube-proxy kubeconfig location\n"
            exit 1
        elif [ -f $KPKUBECONFIG ]
            then
                printf "${NC}kube-proxy kubeconfig file found, verifying the authenticity\n"
                KPKUBECONFIG_SUBJECT=$(cat $KPKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Subject: CN" | tr -d " ")
                KPKUBECONFIG_ISSUER=$(cat $KPKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Issuer: CN" | tr -d " ")
                KPKUBECONFIG_CERT_MD5=$(cat $KPKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 -noout | openssl md5 | awk '{print $2}')
                KPKUBECONFIG_KEY_MD5=$(cat $KPKUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                KPKUBECONFIG_SERVER=$(cat $KPKUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $KPKUBECONFIG_SUBJECT == "Subject:CN=system:kube-proxy" ] && [ $KPKUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KPKUBECONFIG_CERT_MD5 == $KPKUBECONFIG_KEY_MD5 ] && [ $KPKUBECONFIG_SERVER == "https://192.168.5.30:6443" ]
                    then
                        printf "${SUCCESS}kube-proxy kubeconfig cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-proxy kubeconfig certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-proxy-kubernetes-configuration-file\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-proxy kubeconfig file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-proxy-kubernetes-configuration-file\n"
                exit 1
    fi
}

check_cert_kcmkubeconfig()
{
    if [ -z $KCMKUBECONFIG ]
        then
            printf "${FAILED}please specify kube-controller-manager kubeconfig location\n"
            exit 1
        elif [ -f $KCMKUBECONFIG ]
            then
                printf "${NC}kube-controller-manager kubeconfig file found, verifying the authenticity\n"
                KCMKUBECONFIG_SUBJECT=$(cat $KCMKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Subject: CN" | tr -d " ")
                KCMKUBECONFIG_ISSUER=$(cat $KCMKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Issuer: CN" | tr -d " ")
                KCMKUBECONFIG_CERT_MD5=$(cat $KCMKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 -noout | openssl md5 | awk '{print $2}')
                KCMKUBECONFIG_KEY_MD5=$(cat $KCMKUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                KCMKUBECONFIG_SERVER=$(cat $KCMKUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $KCMKUBECONFIG_SUBJECT == "Subject:CN=system:kube-controller-manager" ] && [ $KCMKUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KCMKUBECONFIG_CERT_MD5 == $KCMKUBECONFIG_KEY_MD5 ] && [ $KCMKUBECONFIG_SERVER == "https://127.0.0.1:6443" ]
                    then
                        printf "${SUCCESS}kube-controller-manager kubeconfig cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-controller-manager kubeconfig certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-controller-manager-kubernetes-configuration-file\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-controller-manager kubeconfig file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-controller-manager-kubernetes-configuration-file\n"
                exit 1
    fi
}


check_cert_kskubeconfig()
{
    if [ -z $KSKUBECONFIG ]
        then
            printf "${FAILED}please specify kube-scheduler kubeconfig location\n"
            exit 1
        elif [ -f $KSKUBECONFIG ]
            then
                printf "${NC}kube-scheduler kubeconfig file found, verifying the authenticity\n"
                KSKUBECONFIG_SUBJECT=$(cat $KSKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Subject: CN" | tr -d " ")
                KSKUBECONFIG_ISSUER=$(cat $KSKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Issuer: CN" | tr -d " ")
                KSKUBECONFIG_CERT_MD5=$(cat $KSKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 -noout | openssl md5 | awk '{print $2}')
                KSKUBECONFIG_KEY_MD5=$(cat $KSKUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                KSKUBECONFIG_SERVER=$(cat $KSKUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $KSKUBECONFIG_SUBJECT == "Subject:CN=system:kube-scheduler" ] && [ $KSKUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KSKUBECONFIG_CERT_MD5 == $KSKUBECONFIG_KEY_MD5 ] && [ $KSKUBECONFIG_SERVER == "https://127.0.0.1:6443" ]
                    then
                        printf "${SUCCESS}kube-scheduler kubeconfig cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-scheduler kubeconfig certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-scheduler-kubernetes-configuration-file\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-scheduler kubeconfig file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/05-kubernetes-configuration-files.md#the-kube-scheduler-kubernetes-configuration-file\n"
                exit 1
    fi
}

check_cert_adminkubeconfig()
{
    if [ -z $ADMINKUBECONFIG ]
        then
            printf "${FAILED}please specify admin kubeconfig location\n"
            exit 1
        elif [ -f $ADMINKUBECONFIG ]
            then
                printf "${NC}admin kubeconfig file found, verifying the authenticity\n"
                ADMINKUBECONFIG_SUBJECT=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Subject: CN" | tr -d " ")
                ADMINKUBECONFIG_ISSUER=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Issuer: CN" | tr -d " ")
                ADMINKUBECONFIG_CERT_MD5=$(cat $ADMINKUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 -noout | openssl md5 | awk '{print $2}')
                ADMINKUBECONFIG_KEY_MD5=$(cat $ADMINKUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                ADMINKUBECONFIG_SERVER=$(cat $ADMINKUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $ADMINKUBECONFIG_SUBJECT == "Subject:CN=admin,O=system:masters" ] && [ $ADMINKUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $ADMINKUBECONFIG_CERT_MD5 == $ADMINKUBECONFIG_KEY_MD5 ] && [ $ADMINKUBECONFIG_SERVER == "https://127.0.0.1:6443" ]
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

check_systemd_etcd()
{
    if [ -z $ETCDCERT ] && [ -z $ETCDKEY ]
        then
            printf "${FAILED}please specify ETCD cert and key location, Exiting....\n"
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
                INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
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
                        printf "${SUCCESS}ETCD certificate, ca and key files are correct under systemd service\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ETCD certificate, ca and keys. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n"
                        exit 1
                fi

                if [ $IAP_URL == "https://$INTERNAL_IP:2380" ] && [ $LP_URL == "https://$INTERNAL_IP:2380"  ] && [ $LC_URL == "https://$INTERNAL_IP:2379,https://127.0.0.1:2379" ] && \
                   [ $AC_URL == "https://$INTERNAL_IP:2379" ]
                    then
                        printf "${SUCCESS}ETCD initial-advertise-peer-urls, listen-peer-urls, listen-client-urls, advertise-client-urls are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the ETCD initial-advertise-peer-urls / listen-peer-urls / listen-client-urls / advertise-client-urls. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n"
                        exit 1
                fi

            else
                printf "${FAILED}etcd-server.crt / etcd-server.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/07-bootstrapping-etcd.md#configure-the-etcd-server\n"
                exit 1
    fi
}

check_systemd_api()
{
    if [ -z $APICERT ] && [ -z $APIKEY ]
        then
            printf "${FAILED}please specify kube-api cert and key location, Exiting....\n"
            exit 1
        elif [ -f $SYSTEMD_API_FILE ]
            then
                printf "${NC}Systemd for kube-api service found, verifying the authenticity\n"

                INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
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

                CACERT=/var/lib/kubernetes/ca.crt
                APICERT=/var/lib/kubernetes/kube-apiserver.crt
                APIKEY=/var/lib/kubernetes/kube-apiserver.key
                SACERT=/var/lib/kubernetes/service-account.crt
                if [ $ADVERTISE_ADDRESS == $INTERNAL_IP ] && [ $CLIENT_CA_FILE == $CACERT ] && [ $ETCD_CA_FILE == $CACERT ] && \
                   [ $ETCD_CERT_FILE == "/var/lib/kubernetes/etcd-server.crt" ] && [ $ETCD_KEY_FILE == "/var/lib/kubernetes/etcd-server.key" ] && \
                   [ $KUBELET_CERTIFICATE_AUTHORITY == $CACERT ] && [ $KUBELET_CLIENT_CERTIFICATE == $APICERT ] && [ $KUBELET_CLIENT_KEY == $APIKEY ] && \
                   [ $SERVICE_ACCOUNT_KEY_FILE == $SACERT ] && [ $TLS_CERT_FILE == $APICERT ] && [ $TLS_PRIVATE_KEY_FILE == $APIKEY ]
                    then
                        printf "${SUCCESS}kube-apiserver advertise-address/ client-ca-file/ etcd-cafile/ etcd-certfile/ etcd-keyfile/ kubelet-certificate-authority/ kubelet-client-certificate/ kubelet-client-key/ service-account-key-file/ tls-cert-file/ tls-private-key-file are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-apiserver systemd file, check advertise-address/ client-ca-file/ etcd-cafile/ etcd-certfile/ etcd-keyfile/ kubelet-certificate-authority/ kubelet-client-certificate/ kubelet-client-key/ service-account-key-file/ tls-cert-file/ tls-private-key-file. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-apiserver.crt / kube-apiserver.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server\n"
                exit 1
    fi
}

check_systemd_kcm()
{
    KCMCERT=/var/lib/kubernetes/kube-controller-manager.crt
    KCMKEY=/var/lib/kubernetes/kube-controller-manager.key
    CACERT=/var/lib/kubernetes/ca.crt
    CAKEY=/var/lib/kubernetes/ca.key
    SAKEY=/var/lib/kubernetes/service-account.key
    KCMKUBECONFIG=/var/lib/kubernetes/kube-controller-manager.kubeconfig
    if [ -z $KCMCERT ] && [ -z $KCMKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $SYSTEMD_KCM_FILE ]
            then
                printf "${NC}Systemd for kube-controller-manager service found, verifying the authenticity\n"
                CLUSTER_SIGNING_CERT_FILE=$(systemctl cat kube-controller-manager.service | grep "\--cluster-signing-cert-file" | awk '{print $1}' | cut -d "=" -f2)
                CLUSTER_SIGNING_KEY_FILE=$(systemctl cat kube-controller-manager.service | grep "\--cluster-signing-key-file" | awk '{print $1}' | cut -d "=" -f2)
                KUBECONFIG=$(systemctl cat kube-controller-manager.service | grep "\--kubeconfig" | awk '{print $1}' | cut -d "=" -f2)
                ROOT_CA_FILE=$(systemctl cat kube-controller-manager.service | grep "\--root-ca-file" | awk '{print $1}' | cut -d "=" -f2)
                SERVICE_ACCOUNT_PRIVATE_KEY_FILE=$(systemctl cat kube-controller-manager.service | grep "\--service-account-private-key-file" | awk '{print $1}' | cut -d "=" -f2)

                if [ $CLUSTER_SIGNING_CERT_FILE == $CACERT ] && [ $CLUSTER_SIGNING_KEY_FILE == $CAKEY ] && [ $KUBECONFIG == $KCMKUBECONFIG ] && \
                   [ $ROOT_CA_FILE == $CACERT ] && [ $SERVICE_ACCOUNT_PRIVATE_KEY_FILE == $SAKEY ]
                    then
                        printf "${SUCCESS}kube-controller-manager cluster-signing-cert-file, cluster-signing-key-file, kubeconfig, root-ca-file, service-account-private-key-file  are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-controller-manager cluster-signing-cert-file, cluster-signing-key-file, kubeconfig, root-ca-file, service-account-private-key-file ,More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-controller-manager.crt / kube-controller-manager.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-controller-manager\n"
                exit 1
    fi
}

check_systemd_ks()
{
    KSCERT=/var/lib/kubernetes/kube-scheduler.crt
    KSKEY=/var/lib/kubernetes/kube-scheduler.key
    KSKUBECONFIG=/var/lib/kubernetes/kube-scheduler.kubeconfig

    if [ -z $KSCERT ] && [ -z $KSKEY ]
        then
            printf "${FAILED}please specify cert and key location\n"
            exit 1
        elif [ -f $SYSTEMD_KS_FILE ]
            then
                printf "${NC}Systemd for kube-scheduler service found, verifying the authenticity\n"

                KUBECONFIG=$(systemctl cat kube-scheduler.service | grep "\--kubeconfig"| awk '{print $1}'| cut -d "=" -f2)
                ADDRESS=$(systemctl cat kube-scheduler.service | grep "\--address"| awk '{print $1}'| cut -d "=" -f2)

                if [ $KUBECONFIG == $KSKUBECONFIG ] && [ $ADDRESS == "127.0.0.1" ]
                    then
                        printf "${SUCCESS}kube-scheduler --kubeconfig, --address are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the kube-scheduler --kubeconfig, --address, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler\n"
                        exit 1
                fi
            else
                printf "${FAILED}kube-scheduler.crt / kube-scheduler.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-scheduler\n"
                exit 1
    fi
}

# END OF Function - Master node #

# Function - Worker-1 node #

check_cert_worker_1()
{
    if [ -z $WORKER_1_CERT ] && [ -z $WORKER_1_KEY ]
        then
            printf "${FAILED}please specify cert and key location of worker-1 node\n"
            exit 1
        elif [ -f $WORKER_1_CERT ] && [ -f $WORKER_1_KEY ]
            then
                printf "${NC}worker-1 cert and key found, verifying the authenticity\n"
                WORKER_1_CERT_SUBJECT=$(openssl x509 -in $WORKER_1_CERT -text | grep "Subject: CN"| tr -d " ")
                WORKER_1_CERT_ISSUER=$(openssl x509 -in $WORKER_1_CERT -text | grep "Issuer: CN"| tr -d " ")
                WORKER_1_CERT_MD5=$(openssl x509 -noout -modulus -in $WORKER_1_CERT | openssl md5| awk '{print $2}')
                WORKER_1_KEY_MD5=$(openssl rsa -noout -modulus -in $WORKER_1_KEY | openssl md5| awk '{print $2}')
                if [ $WORKER_1_CERT_SUBJECT == "Subject:CN=system:node:worker-1,O=system:nodes" ] && [ $WORKER_1_CERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $WORKER_1_CERT_MD5 == $WORKER_1_KEY_MD5 ]
                    then
                        printf "${SUCCESS}worker-1 cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the worker-1 certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#provisioning--kubelet-client-certificates\n"
                        exit 1
                fi
            else
                printf "${FAILED}/var/lib/kubelet/worker-1.crt / /var/lib/kubelet/worker-1.key is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#provisioning--kubelet-client-certificates\n"
                exit 1
    fi
}

check_cert_worker_1_kubeconfig()
{
    if [ -z $WORKER_1_KUBECONFIG ]
        then
            printf "${FAILED}please specify worker-1 kubeconfig location\n"
            exit 1
        elif [ -f $WORKER_1_KUBECONFIG ]
            then
                printf "${NC}worker-1 kubeconfig file found, verifying the authenticity\n"
                WORKER_1_KUBECONFIG_SUBJECT=$(cat $WORKER_1_KUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Subject: CN" | tr -d " ")
                WORKER_1_KUBECONFIG_ISSUER=$(cat $WORKER_1_KUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 --text | grep "Issuer: CN" | tr -d " ")
                WORKER_1_KUBECONFIG_CERT_MD5=$(cat $WORKER_1_KUBECONFIG | grep "client-certificate-data:" | awk '{print $2}' | base64 --decode | openssl x509 -noout | openssl md5 | awk '{print $2}')
                WORKER_1_KUBECONFIG_KEY_MD5=$(cat $WORKER_1_KUBECONFIG | grep "client-key-data" | awk '{print $2}' | base64 --decode | openssl rsa -noout | openssl md5 | awk '{print $2}')
                WORKER_1_KUBECONFIG_SERVER=$(cat $WORKER_1_KUBECONFIG | grep "server:"| awk '{print $2}')
                if [ $WORKER_1_KUBECONFIG_SUBJECT == "Subject:CN=system:node:worker-1,O=system:nodes" ] && [ $WORKER_1_KUBECONFIG_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && \
                   [ $WORKER_1_KUBECONFIG_CERT_MD5 == $WORKER_1_KUBECONFIG_KEY_MD5 ] && [ $WORKER_1_KUBECONFIG_SERVER == "https://192.168.5.30:6443" ]
                    then
                        printf "${SUCCESS}worker-1 kubeconfig cert and key are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the worker-1 kubeconfig certificate and keys, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#the-kubelet-kubernetes-configuration-file\n"
                        exit 1
                fi
            else
                printf "${FAILED}worker-1 /var/lib/kubelet/kubeconfig file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#the-kubelet-kubernetes-configuration-file\n"
                exit 1
    fi
}

check_cert_worker_1_kubelet()
{

    CACERT=/var/lib/kubernetes/ca.crt
    WORKER_1_TLSCERTFILE=/var/lib/kubelet/${HOSTNAME}.crt
    WORKER_1_TLSPRIVATEKEY=/var/lib/kubelet/${HOSTNAME}.key
    
    if [ -z $WORKER_1_KUBELET ] && [ -z $SYSTEMD_WORKER_1_KUBELET ]
        then
            printf "${FAILED}please specify worker-1 kubelet config location\n"
            exit 1
        elif [ -f $WORKER_1_KUBELET ] && [ -f $SYSTEMD_WORKER_1_KUBELET ] && [ -f $WORKER_1_TLSCERTFILE ] && [ -f $WORKER_1_TLSPRIVATEKEY ]
            then
                printf "${NC}worker-1 kubelet config file, systemd services, tls cert and key found, verifying the authenticity\n"

                WORKER_1_KUBELET_CA=$(cat $WORKER_1_KUBELET | grep "clientCAFile:" | awk '{print $2}' | tr -d " \"")
                WORKER_1_KUBELET_DNS=$(cat $WORKER_1_KUBELET | grep "resolvConf:" | awk '{print $2}' | tr -d " \"")
                WORKER_1_KUBELET_AUTH_MODE=$(cat $WORKER_1_KUBELET | grep "mode:" | awk '{print $2}' | tr -d " \"")

                if [ $WORKER_1_KUBELET_CA == $CACERT ] && [ $WORKER_1_KUBELET_DNS == "/run/systemd/resolve/resolv.conf" ] && \
                   [ $WORKER_1_KUBELET_AUTH_MODE == "Webhook" ]
                    then
                        printf "${SUCCESS}worker-1 kubelet config CA cert, resolvConf and Auth mode are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the worker-1 kubelet config CA cert, resolvConf and Auth mode, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#configure-the-kubelet\n"
                        exit 1
                fi

                KUBELETCONFIG=$(systemctl cat kubelet.service | grep "\--config" | awk '{print $1}'| cut -d "=" -f2)
                TLSCERTFILE=$(systemctl cat kubelet.service | grep "\--tls-cert-file" | awk '{print $1}'| cut -d "=" -f2)
                TLSPRIVATEKEY=$(systemctl cat kubelet.service | grep "\--tls-private-key-file" | awk '{print $1}'| cut -d "=" -f2)

                if [ $KUBELETCONFIG == $WORKER_1_KUBELET ] && [ $TLSCERTFILE == $WORKER_1_TLSCERTFILE ] && \
                   [ $TLSPRIVATEKEY == $WORKER_1_TLSPRIVATEKEY ]
                    then
                        printf "${SUCCESS}worker-1 kubelet systemd services are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the worker-1 kubelet systemd services, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#configure-the-kubelet\n"
                        exit 1
                fi

            else
                printf "${FAILED}worker-1 kubelet config, systemd services, tls cert and key file is missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md\n"
                exit 1
    fi
}

check_cert_worker_1_kp()
{

    WORKER_1_KP_CONFIG_YAML=/var/lib/kube-proxy/kube-proxy-config.yaml
    
    if [ -z $WORKER_1_KP_KUBECONFIG ] && [ -z $SYSTEMD_WORKER_1_KP ]
        then
            printf "${FAILED}please specify worker-1 kube-proxy config and systemd service path\n"
            exit 1
        elif [ -f $WORKER_1_KP_KUBECONFIG ] && [ -f $SYSTEMD_WORKER_1_KP ] && [ -f $WORKER_1_KP_CONFIG_YAML ]
            then
                printf "${NC}worker-1 kube-proxy kubeconfig, systemd services and configuration files found, verifying the authenticity\n"

                KP_CONFIG=$(cat $WORKER_1_KP_CONFIG_YAML | grep "kubeconfig:" | awk '{print $2}' | tr -d " \"")
                KP_CONFIG_YAML=$(systemctl cat kube-proxy.service | grep "\--config" | awk '{print $1}'| cut -d "=" -f2)

                if [ $KP_CONFIG == $WORKER_1_KP_KUBECONFIG ] && [ $KP_CONFIG_YAML == $WORKER_1_KP_CONFIG_YAML ]
                    then
                        printf "${SUCCESS}worker-1 kube-proxy kubeconfig and configuration files are correct\n"
                    else
                        printf "${FAILED}Exiting...Found mismtach in the worker-1 kube-proxy kubeconfig and configuration files, More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#configure-the-kubernetes-proxy\n"
                        exit 1
                fi

            else
                printf "${FAILED}worker-1 kube-proxy kubeconfig and configuration files are missing. More details: https://github.com/mmumshad/kubernetes-the-hard-way/blob/master/docs/09-bootstrapping-kubernetes-workers.md#configure-the-kubernetes-proxy\n"
                exit 1
    fi
}

# END OF Function - Worker-1 node #

echo -e "This script will validate the certificates in master as well as worker-1 nodes. Before proceeding, make sure you ssh into the respective node [ Master or Worker-1 ] for certificate validation\n"
echo -e "1. Verify certification in Master Node\n"
echo -e "2. Verify certification in Worker-1 Node\n"
echo -e "Please select either the option 1 or 2\n"
read value

case $value in

  1)
    echo -e "The selected option is $value, proceeding the certificate verification of Master node"

    ### MASTER NODES ###
    master_hostname=$(hostname -s)
    # CRT & KEY verification
    check_cert_ca

    if [ $master_hostname == "master-1" ]
      then
        check_cert_admin
        check_cert_kcm
        check_cert_kp
        check_cert_ks
        check_cert_adminkubeconfig
        check_cert_kpkubeconfig
    fi
    check_cert_api
    check_cert_sa
    check_cert_etcd

    # Kubeconfig verification
    check_cert_kcmkubeconfig
    check_cert_kskubeconfig

    # Systemd verification
    check_systemd_etcd
    check_systemd_api
    check_systemd_kcm
    check_systemd_ks

    ### END OF MASTER NODES ###

    ;;

  2)
    echo -e "The selected option is $value, proceeding the certificate verification of Worker-1 node"

    ### WORKER-1 NODE ###

    check_cert_worker_1
    check_cert_worker_1_kubeconfig
    check_cert_worker_1_kubelet
    check_cert_worker_1_kp

    ### END OF WORKER-1 NODE ###
    ;;

  *)
    printf "${FAILED}Exiting.... Please select the valid option either 1 or 2\n"
    exit 1
    ;;
esac