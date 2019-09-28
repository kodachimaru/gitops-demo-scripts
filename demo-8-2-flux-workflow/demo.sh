helm init

# Install Flux

helm repo add fluxcd https://charts.fluxcd.io

# Create Secrets for the Flux instances' git SSH private key
# No need to include the public key, will be automatically derived from the private one
# https://docs.fluxcd.io/en/stable/guides/provide-own-ssh-key.html

kubectl create namespace flux-staging
kubectl create secret generic \
    flux-git-ssh-key-staging \
    --namespace=flux-staging \
    --from-file=identity="../flux-git-ssh-key"

kubectl create namespace flux-prod
kubectl create secret generic \
    flux-git-ssh-key-prod \
    --namespace=flux-prod \
    --from-file=identity="../flux-git-ssh-key"

# Install staging instance
helm install \
    --name flux-staging \
    --set helmOperator.create=true \
    --set helmOperator.createCRD=true \
    --set git.url=git@github.com:kodachimaru/gitops-demo-flux-2-workflow.git \
    --set git.branch=staging \
    --set git.pollInterval=5s \
    --set git.secretName=flux-git-ssh-key-staging \
    --namespace flux-staging \
    fluxcd/flux

# Install prod instance
# Disable installation of HelmRelease CRD, already installed
helm install \
    --name flux-prod \
    --set helmOperator.create=true \
    --set helmOperator.createCRD=false \
    --set git.url=git@github.com:kodachimaru/gitops-demo-flux-2-workflow.git \
    --set git.branch=master \
    --set git.pollInterval=5s \
    --set git.secretName=flux-git-ssh-key-prod \
    --namespace flux-prod \
    fluxcd/flux

# Add our Flux public SSH key to GitHub repo, with read/write access
fluxctl identity --k8s-fwd-ns flux-staging
fluxctl identity --k8s-fwd-ns flux-prod

# Watch Flux in motion
kubectl logs -f $(kubectl get pods -n flux-staging -o name | grep flux | grep -v helm | grep -v memcached) -n flux-staging
kubectl logs -f $(kubectl get pods -n flux-prod -o name | grep flux | grep -v helm | grep -v memcached) -n flux-prod
watch "echo ------------- HELM LIST ; helm list --all ; echo -------------- HELMRELEASE RES LIST ; kubectl get hr --all-namespaces"

# Watch HelmOperator in motion
kubectl logs -f $(kubectl get pods -o name -n flux-staging | grep flux-staging-helm-operator) -n flux-staging
kubectl logs -f $(kubectl get pods -o name -n flux-prod | grep flux-prod-helm-operator) -n flux-prod

# Clone code repo
git clone https://github.com/kodachimaru/gitops-demo-flux-2-workflow
cd gitops-demo-flux-2-workflow

# Set the home base
git checkout env-template

# Create environment from env-template: staging
git checkout -b staging 
git push --set-upstream origin staging
kubectl create namespace staging

# Create environment from env-template: prod
# Prod branch is master
git checkout -b master
git push --set-upstream origin master
kubectl create namespace prod



####### 1 - First trip to prod

# Start from staging branch
git checkout staging
# Create MySQL feature branch by John Doe
git checkout -b johndoe/feature/mysql/staging
git push --set-upstream origin johndoe/feature/mysql/staging

# Copy MySQL HelmRelease from integration branch
git merge origin/integration
# Change data to staging namespace
nano mysql.helmrelease.yaml 

# Commit to staging feature branch
git add .
git commit -m "Adapt to staging environment"
git push

# Go GitHub
# Create PR from feature to staging branch
# Accept PR, delete remote feature branch

# Pull staging changes
git checkout staging
git pull

# Watch MySQL release go live in staging
watch helm status mysql-staging

# Test the release
helm test mysql-staging

# Delete local feature branch
git branch -D johndoe/feature/mysql/staging

# Create feature branch in prod
git checkout master
git checkout -b johndoe/feature/mysql/master
git push --set-upstream origin johndoe/feature/mysql/master

# Merge staging into feature branch
git merge staging

# Change data to prod namespace
nano mysql.helmrelease.yaml 

git add .
git commit -m "Changes for prod"
git push

# Go GitHub
# Create PR from feature to prod branch
# Accept PR, delete remote feature branch

# Delete local feature branch
git checkout master
git pull
git branch -D johndoe/feature/mysql/master



####### 2 - Butting heads with others

# John Doe: 
# Sees perf problems
# Wants to go back to chart v1.1.1
git checkout staging
git checkout -b johndoe/feature/change-mysql-version/staging
git push --set-upstream origin johndoe/feature/change-mysql-version/staging

# Change chart to v1.1.1
nano mysql.helmrelease.yaml 

git add .
git commit -m "[JohnDoe] Performance problems. Rollback mysql release to chart v1.1.1"
git push

# Alexa Kolontai: 
# Sees the same problem, but realizes it comes just from the last two patch update.
# She wants to go back to chart v1.2.0

git checkout staging
git checkout -b akolontai/feature/change-mysql-version/staging
git push --set-upstream origin akolontai/feature/change-mysql-version/staging

# Change chart to v1.2.0
nano mysql.helmrelease.yaml 

git add .
git commit -m "[AlexaKolontai] Performance problems. Rollback mysql release to chart v1.2.0"
git push

# But Kolontai is faster!
# Go GitHub, create & accept PR

git checkout staging
git pull
git branch -D akolontai/feature/change-mysql-version/staging

# Now John has a problem...
git checkout johndoe/feature/change-mysql-version/staging 
# Go GitHub, create & try to accept PR
# --> Can create PR, but can't be merged automatically
# --> John now needs to work with Alexa to reach an agreement
# --> WORKFLOW!!!

# At the end, John realizes Alexa's change is better
# Go GitHub, cancel the PR and delete remote branch

# Delete local branch too
git checkout staging
git branch -D johndoe/feature/change-mysql-version/staging 



# Undo

git checkout env-template

kubectl delete namespace flux-staging
kubectl delete namespace staging
git branch -D staging
git push origin --delete staging

kubectl delete namespace flux-prod
kubectl delete namespace prod
git branch -D master
git push origin --delete master

helm delete --purge mysql-staging
helm delete --purge mysql-prod
helm delete --purge flux-staging
helm delete --purge flux-prod

kubectl delete crd helmreleases.flux.weave.works

helm reset
