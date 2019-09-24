# Helm chart development workflow

# .0- Install Helm
	helm init
	kubectl get deployments -n kube-system
						# NAME            READY   UP-TO-DATE   AVAILABLE   AGE
						# tiller-deploy   1/1     1            1           31s									

# .1- Skeleton creation
	mkdir helm-demo
	helm create helm-nginx-chart
	cd helm-nginx-chart
	tree
	git init
	git checkout -b test

# .2- Development
	# Kube manifest templates
		nano templates/deployment.yaml

	# Subcharts
		helm create charts/sub-nginx
		nano charts/sub-nginx/values.yaml
					# image:
					#   repository: nginx

	# Default config values
		nano values.yaml
				# replicaCount: 2
				# image:
				#   repository: nginx							

				# sub-nginx:
				#   replicaCount: 2

	# Dependencies
		touch requirements.yaml
		nano requirements.yaml
					#dependencies:
					# - name: memcached
					#   version: "2.8.3"
					#   alias: dep-memcached
					#   repository: https://kubernetes-charts.storage.googleapis.com/
		nano values.yaml
					# dep-memcached:
					#   replicaCount: 1

  	# Verify
		helm lint
		helm install --dry-run .
			# Fails!
		helm dependency update
		tree
			# charts: memcached chart is there!
		helm install --dry-run .
			# OK!

	# Commit
		git status
				# chart .tgz file there!
		nano .gitignore
				charts/*.tgz
		git add .
		git commit -m "Test env config"

# .3- Deployment to test env
		helm install --namespace test --name my-chart .
		helm status my-chart

# .4- Testing
		kubectl get pods -n test
		kubectl port-forward my-chart-helm-nginx-chart-7bb86785fb-5tpnl -n test 8080:80

		helm test my-chart
			# Passed! (memcached chart has no tests!)
		kubectl get pods | grep test

# .5- Iterate ...


# .6- Prod env config preparation
		git checkout master
		git merge test
		nano values.yaml
					dep-memcached:
					  replicaCount: 2
					sub-nginx:
					  replicaCount: 2
					replicaCount: 2
		git add .
		git commit -m "Prod config"

# .7- Deployment to prod env
		helm install --namespace prod --name my-chart-prod . 

# .8- Testing
		helm test my-chart-prod

# .9- End
		helm delete my-chart
		helm delete my-chart-prod

		kubectl get pods -n test
		kubectl delete namespace test
		kubectl delete namespace prod

		helm reset


