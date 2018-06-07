#!/bin/bash


### Note! Run as root user
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

echo "Enter RHN User:/n"
read RHN_USER
echo "Enter RHN Password:/n"
read -s RHN_PASSWORD
echo "Enter full path to storage location for export files (requires ~130 GB of available space):/n"
read STORAGE_PATH

IMAGE_STORAGE_PATH=$STORAGE_PATH/images
REPO_STORAGE_PATH=$STORAGE_PATH/repo_files

# STORAGE_SIZE=$(df --output=size /mnt/xyz | awk ' NR==2 ')
# MIN_SIZE=136314880



subscription-manager register --username=$RHN_USER --password=$RHN_PASSWORD
subscription-manager refresh

POOLID=$(/usr/bin/subscription-manager list --all --available --matches="*OpenShift Container*" | awk '/Pool ID/ {print $3}' | head -1)

subscription-manager attach --pool=$POOLID

subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ansible-2.4-rpms" \
    --enable="rhel-7-server-ose-3.9-rpms"

yum -y install yum-utils createrepo docker git
systemctl enable docker
systemctl start docker

mkdir -p $IMAGE_STORAGE_PATH
mkdir -p $REPO_STORAGE_PATH


for repo in \
    rhel-7-server-rpms \
    rhel-7-server-extras-rpms \
    rhel-7-fast-datapath-rpms \
    rhel-7-server-ansible-2.4-rpms \
    rhel-7-server-ose-3.9-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=$REPO_STORAGE_PATH
  createrepo -v $REPO_STORAGE_PATH/${repo} -o $REPO_STORAGE_PATH/${repo}
done

clear
echo "Finished downloading repo files: your files are located in /tmp/repos"
sleep 3

echo "Loggin into registry.access.redhat.com with docker..."
docker login registry.access.redhat.com -u $RHN_USER -p $RHN_PASSWORD


declare -a images=(
        "openshift3/ose-ansible:v3.9.27"
        "openshift3/ose-cluster-capacity:v3.9.27"
        "openshift3/ose-deployer:v3.9.27"
        "openshift3/ose-docker-builder:v3.9.27"
        "openshift3/ose-docker-registry:v3.9.27"
        "openshift3/ose-egress-http-proxy:v3.9.27"
        "openshift3/ose-egress-router:v3.9.27"
        "openshift3/ose-f5-router:v3.9.27"
        "openshift3/ose-haproxy-router:v3.9.27"
        "openshift3/ose-keepalived-ipfailover:v3.9.27"
        "openshift3/ose-pod:v3.9.27"
        "openshift3/ose-sti-builder:v3.9.27"
        "openshift3/ose:v3.9.27"
        "openshift3/container-engine:v3.9.27"
        "openshift3/node:v3.9.27"
        "openshift3/openvswitch:v3.9.27"
        "rhel7/etcd"
        "openshift3/ose-recycler"
        "openshift3/logging-curator:v3.9.27"
        "openshift3/logging-auth-proxy:v3.9.27"
        "openshift3/logging-elasticsearch:v3.9.27"
        "openshift3/logging-fluentd:v3.9.27"
        "openshift3/logging-kibana:v3.9.27"
        "openshift3/metrics-cassandra:v3.9.27"
        "openshift3/metrics-hawkular-metrics:v3.9.27"
        "openshift3/metrics-hawkular-openshift-agent:v3.9.27"
        "openshift3/metrics-heapster:v3.9.27"
        "openshift3/prometheus:v3.9.27"
        "openshift3/prometheus-alert-buffer:v3.9.27"
        "openshift3/prometheus-alertmanager:v3.9.27"
        "openshift3/prometheus-node-exporter:v3.9.27"
        "cloudforms46/cfme-openshift-postgresql:v3.9.27"
        "cloudforms46/cfme-openshift-memcached:v3.9.27"
        "cloudforms46/cfme-openshift-app-ui:v3.9.27"
        "cloudforms46/cfme-openshift-app:v3.9.27"
        "cloudforms46/cfme-openshift-embedded-ansible:v3.9.27"
        "cloudforms46/cfme-openshift-httpd:v3.9.27"
        "cloudforms46/cfme-httpd-configmap-generator:v3.9.27"
        "rhgs3/rhgs-server-rhel7:v3.9.27"
        "rhgs3/rhgs-volmanager-rhel7:v3.9.27"
        "rhgs3/rhgs-gluster-block-prov-rhel7:v3.9.27"
        "rhgs3/rhgs-s3-server-rhel7:v3.9.27"
        "openshift3/ose-service-catalog:v3.9.27"
        "openshift3/ose-ansible-service-broker:v3.9.27"
        "openshift3/mediawiki-apb:v3.9.27"
        "openshift3/postgresql-apb:v3.9.27"
        "rhscl/nodejs-4-rhel7"
        "rhscl/nodejs-6-rhel7"
        "rhscl/ruby-22-rhel7"
        "rhscl/ruby-23-rhel7"
        "rhscl/perl-520-rhel7"
        "rhscl/perl-524-rhel7"
        "rhscl/php-56-rhel7"
        "rhscl/python-27-rhel7"
        "rhscl/python-34-rhel7"
        "dotnet/dotnetcore-10-rhel7"
        "dotnet/dotnetcore-11-rhel7"
        "dotnet/dotnet-20-rhel7"
        "rhscl/httpd-24-rhel7"
        "rhscl/mysql-56-rhel7"
        "rhscl/mysql-57-rhel7"
        "rhscl/mariadb-100-rhel7"
        "rhscl/mariadb-101-rhel7"
        "rhscl/postgresql-94-rhel7"
        "rhscl/postgresql-95-rhel7"
        "rhscl/mongodb-26-rhel7"
        "rhscl/mongodb-32-rhel7"
        "rhscl/redis-32-rhel7"
        "jboss-eap-6/eap64-openshift"
        "jboss-eap-7/eap70-openshift"
        "jboss-eap-7/eap71-openshift"
        "jboss-webserver-3/webserver30-tomcat8-openshift"
        "jboss-webserver-3/webserver31-tomcat8-openshift"
        "jboss-amq-6/amq62-openshift"
        "jboss-amq-6/amq63-openshift"
        "redhat-openjdk-18/openjdk18-openshift"
        "redhat-sso-7/sso71-openshift"
        "redhat-sso-7/sso72-openshift"
        "openshift3/registry-console:v3.9.27"
        "openshift3/jenkins-1-rhel7:v3.9.27"
        "openshift3/jenkins-2-rhel7:v3.9.27"
        "openshift3/jenkins-slave-base-rhel7:v3.9.27"
        "openshift3/jenkins-slave-maven-rhel7:v3.9.27"
        "openshift3/jenkins-slave-nodejs-rhel7:v3.9.27"
        "rhscl/postgresql-96-rhel7:latest"
        "openshift3/oauth-proxy:latest"
)


# Pull the images
echo "Pulling docker images now..."
for i in "${images[@]}"
do
   docker pull registry.access.redhat.com/$i
done

# Grab nexus image
docker pull registry.connect.redhat.com/sonatype/nexus-repository-manager

# download coreos images
docker pull quay.io/quay/redis:latest
docker pull quay.io/coreos/quay:v2.9.1



# Save the images
echo "Saving docker images now..."

IDS=$(docker images | awk '{if ($1 ~ /^(registry|quay)/) print $3}')
docker save $IDS -o $IMAGE_STORAGE_PATH/ocp_docker_images.tar

docker images | sed '1d' | awk '{print $1 " " $2 " " $3}' > $IMAGE_STORAGE_PATH/ocp_docker_images.list

echo "Downloading infra-ansible roles..."
git clone https://github.com/redhat-cop/infra-ansible.git $REPO_STORAGE_PATH/quay-role


echo "Finished/n"
echo "Your files are located in $STORAGE_PATH. Please export the entirety of $STORAGE_PATH onto an external disk."

