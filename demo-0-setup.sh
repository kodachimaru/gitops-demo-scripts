
# Create minikube instance for the demo
minikube start -p flux-demo --memory 8192

# See kube internal resources
kubectl get all --all-namespaces 

# Create ssh key for Flux
ssh-keygen -t rsa -b 4096 -f flux-git-ssh-key -N '' -C flux-git-ssh-key


# Undo

# Destroy minikube
minikube delete -p flux-demo
