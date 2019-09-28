helm init


# Install Helm Operator

# Install the HelmRelease CRD, managed by the HelmOperator
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flux/master/deploy-helm/flux-helm-release-crd.yaml
kubectl api-resources | grep flux
	# We have a new resource kind: helmrelease

# Install the operator
kubectl apply -f https://raw.githubusercontent.com/weaveworks/flux/master/deploy-helm/helm-operator-deployment.yaml





# Init Helm
helm init

# Install Flux

helm repo add fluxcd https://charts.fluxcd.io

# Repo URL not important here (we just use the Helm Op)
helm install \
	--name flux \
	--set helmOperator.create=true \
	--set helmOperator.createCRD=true \
    --set git.url=git@github.com:kodachimaru/gitops-demo-flux-4-git-secret.git \
	--set git.branch=staging \
	--set git.pollInterval=5s \
	--namespace flux \
	fluxcd/flux



# Verify installation
kubectl logs -f $(kubectl get pods -o name -n flux | grep flux-helm-operator) -n flux



# Install Flux Operator

kubectl apply -f https://raw.githubusercontent.com/justinbarrick/flux-operator/master/deploy/flux-operator-cluster.yaml

# Watch Flux Operator (ns "default")
watch kubectl get all -n default
kubectl logs -f $(kubectl get pods -o name -n default | grep flux-operator) -n default

# Deploy the Flux config
kubectl create namespace team-kolontai
kubectl apply -f ./gitops-demo-flux-operator/team-kolontai.flux.yaml

# Watch the Flux instance created by the Operator
watch kubectl get all -n team-kolontai
kubectl logs -f $(kubectl get pods -n team-kolontai -o name | grep flux | grep -v memcached) -n team-kolontai

# Get autogenerated SSH key from the created Flux instance
# Add it to GitHub repo, read/write access (more on this later)
fluxctl identity --k8s-fwd-ns team-kolontai

# Watch the resources created by the autogenerated Flux instance
watch kubectl get all -n team-kolontai


# Undo

kubectl delete -f https://raw.githubusercontent.com/justinbarrick/flux-operator/master/deploy/flux-operator-cluster.yaml
helm delete --purge flux
kubectl delete crd helmreleases.flux.weave.works
kubectl delete namespace team-kolontai
helm reset
helm repo remove fluxcd
