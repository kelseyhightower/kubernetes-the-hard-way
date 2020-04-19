#!/bin/bash
set -e
set -x

# All Cert Location

# ca certificate location
CACERT=/var/lib/kubernetes/ca.crt
CAKEY=/var/lib/kubernetes/ca.key

# admin certificate location
ADMINCERT=/var/lib/kubernetes/admin.crt
ADMINKEY=/var/lib/kubernetes/admin.key

# Kube controller manager certificate location
KCMCERT=/var/lib/kubernetes/kube-controller-manager.crt
KCMKEY=/var/lib/kubernetes/kube-controller-manager.key

# Kube proxy certificate location
KPCERT=/var/lib/kubernetes/kube-proxy.crt
KPKEY=/var/lib/kubernetes/kube-proxy.key

# Kube scheduler certificate location
KSCERT=/var/lib/kubernetes/kube-scheduler.crt
KSKEY=/var/lib/kubernetes/kube-scheduler.key

# Kube api certificate location
APICERT=/var/lib/kubernetes/kube-apiserver.crt
APIKEY=/var/lib/kubernetes/kube-apiserver.key

# ETCD certificate location
ETCDCERT=/var/lib/kubernetes/etcd-server.crt
ETCDKEY=/var/lib/kubernetes/etcd-server.key

# Service account certificate location
SACERT=/var/lib/kubernetes/service-account.crt
SAKEY=/var/lib/kubernetes/service-account.key

check_cert_ca()
{
    if [ -z $CACERT ] && [ -z $CAKEY ]
        then
            echo "please specify cert and key location"
            exit 1
        elif [ -f $CACERT ] && [ -f $CAKEY ]
            then
                echo "CA cert and key found, verifying the authenticity"
                CACERT_SUBJECT=$(openssl x509 -in $CACERT -text | grep "Subject: CN"| tr -d " ")
                CACERT_ISSUER=$(openssl x509 -in $CACERT -text | grep "Issuer: CN"| tr -d " ")
                CACERT_MD5=$(openssl x509 -noout -modulus -in $CACERT | openssl md5| awk '{print $2}')
                CAKEY_MD5=$(openssl rsa -noout -modulus -in $CAKEY | openssl md5| awk '{print $2}')
                if [ $CACERT_SUBJECT == "Subject:CN=KUBERNETES-CA" ] && [ $CACERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $CACERT_MD5 == $CAKEY_MD5 ]
                    then
                        echo "CA cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the CA certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "ca.crt / ca.key is missing"
                exit 1
    fi
}


check_cert_admin()
{
    if [ -z $ADMINCERT ] && [ -z $ADMINKEY ]
        then
            echo "please specify cert and key location"
            exit 1
        elif [ -f $ADMINCERT ] && [ -f $ADMINKEY ]
            then
                echo "admin cert and key found, verifying the authenticity"
                ADMINCERT_SUBJECT=$(openssl x509 -in $ADMINCERT -text | grep "Subject: CN"| tr -d " ")
                ADMINCERT_ISSUER=$(openssl x509 -in $ADMINCERT -text | grep "Issuer: CN"| tr -d " ")
                ADMINCERT_MD5=$(openssl x509 -noout -modulus -in $ADMINCERT | openssl md5| awk '{print $2}')
                ADMINKEY_MD5=$(openssl rsa -noout -modulus -in $ADMINKEY | openssl md5| awk '{print $2}')
                if [ $ADMINCERT_SUBJECT == "Subject:CN=admin,O=system:masters" ] && [ $ADMINCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $ADMINCERT_MD5 == $ADMINKEY_MD5 ]
                    then
                        echo "admin cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the admin certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "admin.crt / admin.key is missing"
                exit 1
    fi
}

check_cert_kcm()
{
    if [ -z $KCMCERT ] && [ -z $KCMKEY ]
        then
            echo "please specify cert and key location"
            exit 1
        elif [ -f $KCMCERT ] && [ -f $KCMKEY ]
            then
                echo "kube-controller-manager cert and key found, verifying the authenticity"
                KCMCERT_SUBJECT=$(openssl x509 -in $KCMCERT -text | grep "Subject: CN"| tr -d " ")
                KCMCERT_ISSUER=$(openssl x509 -in $KCMCERT -text | grep "Issuer: CN"| tr -d " ")
                KCMCERT_MD5=$(openssl x509 -noout -modulus -in $KCMCERT | openssl md5| awk '{print $2}')
                KCMKEY_MD5=$(openssl rsa -noout -modulus -in $KCMKEY | openssl md5| awk '{print $2}')
                if [ $KCMCERT_SUBJECT == "Subject:CN=system:kube-controller-manager" ] && [ $KCMCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KCMCERT_MD5 == $KCMKEY_MD5 ]
                    then
                        echo "kube-controller-manager cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the kube-controller-manager certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "kube-controller-manager.crt / kube-controller-manager.key is missing"
                exit 1
    fi
}

check_cert_kp()
{
    if [ -z $KPCERT ] && [ -z $KPKEY ]
        then
            echo "please specify cert and key location"
            exit 1
        elif [ -f $KPCERT ] && [ -f $KPKEY ]
            then
                echo "kube-proxy cert and key found, verifying the authenticity"
                KPCERT_SUBJECT=$(openssl x509 -in $KPCERT -text | grep "Subject: CN"| tr -d " ")
                KPCERT_ISSUER=$(openssl x509 -in $KPCERT -text | grep "Issuer: CN"| tr -d " ")
                KPCERT_MD5=$(openssl x509 -noout -modulus -in $KPCERT | openssl md5| awk '{print $2}')
                KPKEY_MD5=$(openssl rsa -noout -modulus -in $KPKEY | openssl md5| awk '{print $2}')
                if [ $KPCERT_SUBJECT == "Subject:CN=system:kube-proxy" ] && [ $KPCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KPCERT_MD5 == $KPKEY_MD5 ]
                    then
                        echo "kube-proxy cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the kube-proxy certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "kube-proxy.crt / kube-proxy.key is missing"
                exit 1
    fi
}

check_cert_ks()
{
    if [ -z $KSCERT ] && [ -z $KSKEY ]
        then
            echo "please specify cert and key location"
            exit 1
        elif [ -f $KSCERT ] && [ -f $KSKEY ]
            then
                echo "kube-scheduler cert and key found, verifying the authenticity"
                KSCERT_SUBJECT=$(openssl x509 -in $KSCERT -text | grep "Subject: CN"| tr -d " ")
                KSCERT_ISSUER=$(openssl x509 -in $KSCERT -text | grep "Issuer: CN"| tr -d " ")
                KSCERT_MD5=$(openssl x509 -noout -modulus -in $KSCERT | openssl md5| awk '{print $2}')
                KSKEY_MD5=$(openssl rsa -noout -modulus -in $KSKEY | openssl md5| awk '{print $2}')
                if [ $KSCERT_SUBJECT == "Subject:CN=system:kube-scheduler" ] && [ $KSCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $KSCERT_MD5 == $KSKEY_MD5 ]
                    then
                        echo "kube-scheduler cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the kube-scheduler certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "kube-scheduler.crt / kube-scheduler.key is missing"
                exit 1
    fi
}

check_cert_api()
{
    if [ -z $APICERT ] && [ -z $APIKEY ]
        then
            echo "please specify kube-api cert and key location, Exiting...."
            exit 1
        elif [ -f $APICERT ] && [ -f $APIKEY ]
            then
                echo "kube-apiserver cert and key found, verifying the authenticity"
                APICERT_SUBJECT=$(openssl x509 -in $APICERT -text | grep "Subject: CN"| tr -d " ")
                APICERT_ISSUER=$(openssl x509 -in $APICERT -text | grep "Issuer: CN"| tr -d " ")
                APICERT_MD5=$(openssl x509 -noout -modulus -in $APICERT | openssl md5| awk '{print $2}')
                APIKEY_MD5=$(openssl rsa -noout -modulus -in $APIKEY | openssl md5| awk '{print $2}')
                if [ $APICERT_SUBJECT == "Subject:CN=kube-apiserver" ] && [ $APICERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $APICERT_MD5 == $APIKEY_MD5 ]
                    then
                        echo "kube-apiserver cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the kube-apiserver certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "kube-apiserver.crt / kube-apiserver.key is missing"
                exit 1
    fi
}

check_cert_etcd()
{
    if [ -z $ETCDCERT ] && [ -z $ETCDKEY ]
        then
            echo "please specify ETCD cert and key location, Exiting...."
            exit 1
        elif [ -f $ETCDCERT ] && [ -f $ETCDKEY ]
            then
                echo "ETCD cert and key found, verifying the authenticity"
                ETCDCERT_SUBJECT=$(openssl x509 -in $ETCDCERT -text | grep "Subject: CN"| tr -d " ")
                ETCDCERT_ISSUER=$(openssl x509 -in $ETCDCERT -text | grep "Issuer: CN"| tr -d " ")
                ETCDCERT_MD5=$(openssl x509 -noout -modulus -in $ETCDCERT | openssl md5| awk '{print $2}')
                ETCDKEY_MD5=$(openssl rsa -noout -modulus -in $ETCDKEY | openssl md5| awk '{print $2}')
                if [ $ETCDCERT_SUBJECT == "Subject:CN=etcd-server" ] && [ $ETCDCERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $ETCDCERT_MD5 == $ETCDKEY_MD5 ]
                    then
                        echo "etcd-server.crt / etcd-server.key are correct"
                    else
                        echo "Exiting...Found mismtach in the ETCD certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "etcd-server.crt / etcd-server.key is missing"
                exit 1
    fi
}

check_cert_sa()
{
    if [ -z $SACERT ] && [ -z $SAKEY ]
        then
            echo "please specify Service Account cert and key location, Exiting...."
            exit 1
        elif [ -f $SACERT ] && [ -f $SAKEY ]
            then
                echo "service account cert and key found, verifying the authenticity"
                SACERT_SUBJECT=$(openssl x509 -in $SACERT -text | grep "Subject: CN"| tr -d " ")
                SACERT_ISSUER=$(openssl x509 -in $SACERT -text | grep "Issuer: CN"| tr -d " ")
                SACERT_MD5=$(openssl x509 -noout -modulus -in $SACERT | openssl md5| awk '{print $2}')
                SAKEY_MD5=$(openssl rsa -noout -modulus -in $SAKEY | openssl md5| awk '{print $2}')
                if [ $SACERT_SUBJECT == "Subject:CN=service-accounts" ] && [ $SACERT_ISSUER == "Issuer:CN=KUBERNETES-CA" ] && [ $SACERT_MD5 == $SAKEY_MD5 ]
                    then
                        echo "Service Account cert and key are correct"
                    else
                        echo "Exiting...Found mismtach in the Service Account certificate and keys, check subject"
                        exit 1
                fi
            else
                echo "service-account.crt / service-account.key is missing"
                exit 1
    fi
}

check_cert_ca
check_cert_admin
check_cert_kcm
check_cert_kp
check_cert_ks
check_cert_api
check_cert_sa
check_cert_etcd