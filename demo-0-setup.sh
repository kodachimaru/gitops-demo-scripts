
# Create minikube instance for the demo
minikube start -p flux-demo --memory 8192

# See kube internal resources
kubectl get all --all-namespaces 

# Destroy minikube
minikube delete -p flux-demo
