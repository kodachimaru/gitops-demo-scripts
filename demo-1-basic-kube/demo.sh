# Deployment = ReplicaSet + Pod

kubectl create deployment nginx --image=nginx
kubectl get deployments
kubectl get pods
kubectl delete pod nginx-65f88748fd-qn4k5
kubectl get pods 		# Still there...
kubectl get replicasets
kubectl delete replicaset nginx-65f88748fd
kubectl get replicasets # Still there
kubectl delete deployment nginx
kubectl get pods 		# Not there...
