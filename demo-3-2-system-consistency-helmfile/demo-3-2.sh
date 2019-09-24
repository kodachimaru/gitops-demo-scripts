# Init Helm
helm init
watch helm version


# Create charts
helm create my-chart-1
helm create my-chart-2

# Install charts
helm install my-chart-1 --name my-release-1
helm install my-chart-2 --name my-release-2
watch helm list
helm status my-release-1
helm status my-release-2

# Test charts
helm test --cleanup my-release-1
helm test --cleanup my-release-2


# Now with Helmfile

# Integration with existing current releases
helmfile status
helmfile apply
	# No changes
helmfile delete --purge

# Using Helmfile from scratch
helmfile apply
helmfile status
helmfile test --cleanup

# Filtering releases with labels
helmfile --selector release-name=my-release-1 status
helmfile --selector owner=me status

# Filtering releases to test
helmfile --selector release-name=my-release-1 test --cleanup 


# Uninstall all charts
helmfile delete --purge


# Uninstall Helm
helm reset
