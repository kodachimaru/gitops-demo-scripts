# Init Helm
helm init
watch helm version


# Create superchart
helm create my-super-chart

# Install superchart
helm install my-super-chart --name my-release
watch helm status my-release

# Test superchart
helm test --cleanup my-release


# Create inline subchart
helm create my-super-chart/charts/my-sub-chart

# Install inline subchart
helm upgrade my-release ./my-super-chart
watch helm status my-release

# Test superchart & inline subchart
helm test --cleanup my-release


# Declare dependency subchart
cat > my-super-chart/requirements.yaml
	# dependencies:
	# - name: ambassador
	#   version: "2.12.0"
	#   alias: dep-ambassador
	#   repository: https://kubernetes-charts.storage.googleapis.com/

# Install dep subchart
helm dependency update ./my-super-chart
helm upgrade my-release ./my-super-chart
watch helm status my-release

# Test superchart, inline subchart & dep subchart
helm test --cleanup my-release


# Uninstall superchart
helm delete --purge my-release
# Delete CRD's (created by Ambassador chart)
kubectl delete crd --all

# Uninstall Helm
helm reset