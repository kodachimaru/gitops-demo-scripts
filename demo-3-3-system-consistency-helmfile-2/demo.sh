#   Prerequisites:
#     - Install Helmfile binary: https://github.com/roboll/helmfile#installation
#     - Install Helm Diff plugin for Helm: https://github.com/databus23/helm-diff#install

# Init Helm
helm init

# Use Helmfile
cd helm

# Configure env variables used in our Helmfile
export STACK=integration

# Due to limitations of Helmfile (see helmfile.yaml), we pass the list of charts here
# We build it from the subdirs of ./charts 
# == "kafka-manager|kafka-rest-proxy"
export HELMFILE_RELEASES_LIST="$(ls -1F ./charts | grep -e '.*/$' | sed -e 's/\/$//' | tr '\n' '|' | sed -e 's/\|$//' )"

# See status.
# Will fail, no releases installed yet.
helmfile status

# Install all releases
helmfile apply

# See status of kafka-manager
helmfile \
    --selector release-name=kafka-manager \
    status

# See status of kafka-rest-proxy
helmfile \
    --selector release-name=kafka-rest-proxy \
    status

# Test all releases
# Will fail, Kafka/Zookeeper are not available
helmfile test --cleanup

# Uninstall all releases
helmfile destroy

# Undo
kubectl delete namespace demo
helm reset
