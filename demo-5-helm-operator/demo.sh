helm init



# Install Helm Operator

# Install the HelmRelease CRD, managed by the HelmOperator
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/flux-helm-release-crd.yaml
kubectl api-resources | grep flux
	# We have a new resource kind: helmrelease

kubectl create serviceaccount flux-helm-operator
kubectl create clusterrolebinding flux-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=default:flux-helm-operator

kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/helm-operator-deployment.yaml

# Verify installation
kubectl logs -f $(kubectl get pods -o name | grep flux-helm-operator)



# Create a HelmRelease for MongoDB
kubectl create namespace demo
#kubectl apply -f https://raw.githubusercontent.com/weaveworks/flux-get-started/master/releases/mongodb.yaml
# HR CRD api group name has changed!
kubectl apply -f ./helmrelease-mongodb.yaml
watch helm status mongodb

# List releases with just kubectl!
kubectl get helmreleases --all-namespaces
kubectl describe helmrelease mongodb --namespace demo

# Delete MongoDB release
kubectl delete helmrelease mongodb --namespace demo



# Create a chart-of-charts
#kubectl apply -f https://raw.githubusercontent.com/kodachimaru/gitops-demo-helm-operator/7ab5eb13164539d99ed2d377d9875397b7ea1ec6/chart-of-charts.helmrelease.yaml
kubectl apply -f https://raw.githubusercontent.com/kodachimaru/gitops-demo-helm-operator/master/chart-of-charts.helmrelease.yaml

# List charts
helm list --all
	# Both "chart-of-chart" and "mysql" releases are deployed!
	# Chart "coc" installs subchart "nginx" and HelmRelease "mysql"
	# HelmRelease resource "mysql" triggers the installation of the "mysql" chart

# Test "coc"
helm test chart-of-charts --cleanup
	# Only "nginx" is tested!
	# Helm doesn't know about HelmRelease resources

# Test "mysql"
helm test mysql --cleanup

# Delete "mysql" release using Helm CLI --> HelmOp recreates it (HR CRD still present)
helm delete --purge mysql
	# If not using --purge HelmOp cannot recreate it!
	# Delete HelmOp pod to avoid waiting for the demo...

# Delete "coc"
kubectl delete helmrelease chart-of-charts

# List releases
helm list --all
	# Both nginx and mysql are deleted AND PURGED! History is not kept!
	# 	Reason: HelmRelease resource represents the presence of the release in the system
	# As the HelmRelease "mysql" resource is deleted, the release "mysql" is uninstalled by HelmOperator

# Undo
kubectl delete deployment flux-helm-operator
kubectl delete crd helmreleases.helm.fluxcd.io 
kubectl delete clusterrolebinding flux-cluster-rule 
kubectl delete serviceaccount flux-helm-operator


helm reset
