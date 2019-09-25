# Init Helm
helm init

# Use Helmfile
cd helm

# Configure env variables used in our Helmfile
export STACK=integration

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
