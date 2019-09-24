# Bug report for: https://github.com/fluxcd/flux/issues/2462

# Fork my repo on GitHub and replace it for the following steps
#	https://github.com/kodachimaru/gitops-demo-flux-4-git-secret.git

# Clone repo
git clone https://github.com/kodachimaru/gitops-demo-flux-4-git-secret.git
cd gitops-demo-flux-4-git-secret

# Switch to the proper branch
git checkout support-request

# Import the gpg key to verify the secret can be decrypted alright
gpg --import git-secret-demo.key

# Decrypt the secret
git secret cat the-secret.secret.yaml.secret
git secret reveal -f
		# apiVersion: v1
		# kind: Secret
		# metadata:
		#   name: the-secret
		#   namespace: staging
		# type: Opaque
		# stringData:
		#   secret-file.txt: |-
		#     THIS_IS_MY_SECRET_CONTENT

# Create minikube instance for the demo
minikube start -p flux-demo --memory 8192

# Create Secret from GPG key
kubectl create namespace flux
kubectl create secret generic git-secret-gpg-keys --from-file=git-secret-demo.key -n flux
kubectl describe secret git-secret-gpg-keys -n flux

# Init Helm
helm init

# Install Flux

helm repo add fluxcd https://fluxcd.github.io/flux

helm install \
    --name flux \
    --set helmOperator.create=true \
    --set helmOperator.createCRD=true \
    --set git.url=git@github.com:kodachimaru/gitops-demo-flux-4-git-secret.git \
    --set git.branch=support-request \
    --set git.pollInterval=5s \
    --set additionalArgs[0]="--git-secret" \
    --set gpgKeys.secretName=git-secret-gpg-keys \
    --namespace flux \
    fluxcd/flux

helm list flux
		# NAME	REVISION	UPDATED                 	STATUS  	CHART      	APP VERSION	NAMESPACE
		# flux	1       	Sun Sep 22 18:54:50 2019	DEPLOYED	flux-0.14.1	1.14.2     	flux     

# See GPG key imported
kubectl logs $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux | grep GPG
		# ts=2019-09-22T16:55:52.305875521Z caller=main.go:334 info="imported GPG key(s) from /root/gpg-import/private" files=[git-secret-demo.key]

# See git-secret being used
kubectl logs $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux | grep git-secret
		# ts=2019-09-22T16:55:52.441021379Z caller=main.go:623 url=git@github.com:kodachimaru/gitops-demo-flux-4-git-secret.git user="Weave Flux" email=support@weave.works signing-key= verify-signatures=false sync-tag=flux-sync state=git readonly=false notes-ref=flux set-author=false git-secret=true

# Get deploy key from Flux installation
export FLUX_FORWARD_NAMESPACE=flux
fluxctl identity

# See Flux at work
kubectl logs -f $(kubectl get pods -n flux -o name | grep flux | grep -v helm | grep -v memcached) -n flux

# See the deployment is installed successfully
kubectl get all -n staging
		# NAME                                      READY   STATUS              RESTARTS   AGE
		# pod/busybox-deployment-5d65888d7f-bdf7z   0/1     ContainerCreating   0          5m42s
		# 
		# NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
		# deployment.apps/busybox-deployment   0/1     1            0           5m43s
		# 
		# NAME                                            DESIRED   CURRENT   READY   AGE
		# replicaset.apps/busybox-deployment-5d65888d7f   1         1         0       5m43s

# But not the secret!
# The pod obviously is not starting because the secret cannot be mounted in it as a volume
kubectl get secrets -n staging
		# NAME                  TYPE                                  DATA   AGE
		# default-token-jtlqn   kubernetes.io/service-account-token   3      7m11s

# Enter into the pod 
kubectl exec -it -n flux  $(kubectl get pods -n flux | grep flux | grep -v helm | grep -v memcached | cut -d " " -f 1) /bin/bash

# List the files in the "working" directory
# See that the secret is correctly revealed!
ls -la /tmp/*working*/
		# /tmp/flux-working953999195/:
		# total 44
		# drwx------    4 root     root          4096 Sep 22 17:05 .
		# drwxrwxrwt    1 root     root          4096 Sep 22 17:23 ..
		# drwxr-xr-x    8 root     root          4096 Sep 22 17:05 .git
		# -rw-r--r--    1 root     root            61 Sep 22 17:05 .gitignore
		# drwxr-xr-x    4 root     root          4096 Sep 22 17:05 .gitsecret
		# -rw-r--r--    1 root     root            87 Sep 22 17:05 README.md
		# -rw-r--r--    1 root     root          2519 Sep 22 17:05 git-secret-demo.key
		# -rw-r--r--    1 root     root           826 Sep 22 17:05 secret.deployment.yaml
		# -rw-r--r--    1 root     root            58 Sep 22 17:05 staging.namespace.yaml
		# -rw-r--r--    1 root     root           156 Sep 22 17:05 the-secret.secret.yaml		<==========
		# -rw-r--r--    1 root     root           475 Sep 22 17:05 the-secret.secret.yaml.secret

cat /tmp/flux-working*/the-secret.secret.yaml
		# apiVersion: v1
		# kind: Secret
		# metadata:
		#   name: the-secret
		#   namespace: staging
		# type: Opaque
		# stringData:
		#   secret-file.txt: |-
		#     THIS_IS_MY_SECRET_CONTENT

