
# Create minikube instance for the demo
minikube start -p flux-demo --memory 8192

# See kube internal resources
kubectl get all --all-namespaces 

# Create ssh key for Flux
# https://github.com/fluxcd/flux/blob/1.12.2/test/e2e/e2e-git.sh#L11-L12
ssh-keygen -t rsa -b 4096 -f flux-git-ssh-key -N '' -C flux-git-ssh-key


# Undo

# Destroy minikube
minikube delete -p flux-demo
