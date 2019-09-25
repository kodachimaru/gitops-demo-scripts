
# secret.deployment.yaml
# 	--> the-secret.secret.yaml
# 			* plaintext!

git clone https://github.com/kodachimaru/gitops-demo-flux-4-git-secret.git
cd gitops-demo-flux-4-git-secret

# Switch to staging branch
git checkout -b staging
git push --set-upstream origin staging

# Generate a new GPG key, NO PASSPHRASE!
gpg \
	--batch \
	--passphrase '' \
	--quick-generate-key git-secret-demo

# Enable my user to use git-secret
git secret init
git secret tell git-secret-demo
git add .
git commit -m "Added GPG key git-secret-demo user to git-secret"
git push

# Backup the secret in an uncommitted file
cp the-secret.secret.yaml ./the-secret.secret.yaml.backup

# Delete the secret file from the repository
rm the-secret.secret.yaml
git add the-secret.secret.yaml
git commit -m "Removed plaintext secret"
git push

# Restore the secret's file name, now uncommitted
mv the-secret.secret.yaml.backup the-secret.secret.yaml

# Add an encrypted file
git secret add the-secret.secret.yaml

	# git-ignore has added the file to .gitignore and mapping.cfg	
	git status
		#	modified:   .gitignore
		#	modified:   .gitsecret/paths/mapping.cfg
	cat .gitignore
		# the-secret.secret.yaml
		# 		So that we don't commit again the file accidentally
	cat .gitsecret/paths/mapping.cfg
		# the-secret.secret.yaml
		#		The files to be encrypted

	# The file is not encrypted yet
	cat the-secret.secret.yaml 

# Encrypt all files added to git-secret
git secret hide

	# New uncommitted file has been created
	git status
		# the-secret.secret.yaml.secret
	cat the-secret.secret.yaml.secret 

# Check the encrypted file
git secret cat the-secret.secret.yaml.secret
	# git-secret asks for the GPG key passphrase

# Commit the encrypted file
git add .
git commit -m "Added encrypted Secret"
git push

# Careful! The unencrypted file is still there!
ls

# Remove the unencrypted secret...
rm the-secret.secret.yaml

# Print the secret
git secret cat the-secret.secret.yaml.secret
	# Shows secret by stdout

# Decrypt the file
git secret reveal -f
	# Encrypted files are decrypted and .secret extension removed
	ls -l
	git status
		# No files tracked
		# .yaml is in .gitignore
		# .secret is unchanged
	# Show original & decrypted files
	cat the-secret.secret.yaml
	git secret cat the-secret.secret.yaml.secret

# Delete the plaintext file
rm the-secret.secret.yaml



# Export GPG key
gpg --export-secret-key git-secret-demo > git-secret-demo.key
cat git-secret-demo.key
# Create Secret from GPG key
kubectl create namespace flux
kubectl create secret generic git-secret-gpg-keys --from-file=git-secret-demo.key -n flux
kubectl describe secret git-secret-gpg-keys -n flux

# Remove exported GPG key
rm git-secret-demo.key

# Init Helm
helm init

# Install Flux

helm repo add fluxcd https://fluxcd.github.io/flux


# TODO: Once git-secret integration issue has been resolved (https://github.com/fluxcd/flux/issues/2462)
#			* Remove known_hosts overriding
#			* Remove Flux image tag overriding
# Create known_hosts file for Flux to accept GitHub repos
ssh-keyscan github.com > ./github_known_hosts
helm install \
	--name flux \
	--set helmOperator.create=true \
	--set helmOperator.createCRD=true \
    --set git.url=git@github.com:kodachimaru/gitops-demo-flux-4-git-secret.git \
	--set git.branch=staging \
	--set git.pollInterval=5s \
	--set additionalArgs[0]="--git-secret" \
	--set additionalArgs[1]="--k8s-verbosity=5" \
	--set gpgKeys.secretName=git-secret-gpg-keys \
    --set image.repository=docker.io/kyon/flux \
    --set image.tag=v1.14.2 \
    --set-file ssh.known_hosts=./github_known_hosts \
	--namespace flux \
	fluxcd/flux



# Watch Flux start correctly
watch helm status flux
# See Flux at work
kubectl logs -f $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux
# See GPG key imported
kubectl logs $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux | grep GPG
# See git-secret being used
kubectl logs $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux | grep git-secret



# See Flux installing the Secret & workloads
watch "kubectl get secrets -n staging ; echo; kubectl get all -n staging"
# See the Deployment accessing the unencrypted Secret!
watch kubectl logs -f $(kubectl get pods -n staging -o name | grep busybox) -n staging


# Get autogenerated SSH key
# Add it to GitHub repo, read/write access
export FLUX_FORWARD_NAMESPACE=flux
fluxctl identity



# UNDO

helm delete --purge flux
kubectl delete crd helmreleases.flux.weave.works
helm reset

kubectl delete namespaces staging flux

gpg --delete-secret-and-public-key git-secret-demo

git checkout master
git branch -D staging 
git push origin --delete staging

cd ..
rm -rf gitops-demo-flux-4-git-secret