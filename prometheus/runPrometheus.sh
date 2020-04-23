kubectl delete configmap prometheus-config -n monitoring
kubectl create configmap prometheus-config --from-file=./prometheus.yml -n monitoring
kubectl delete -f prometheus-deployment.yaml 
kubectl create -f prometheus-deployment.yaml 