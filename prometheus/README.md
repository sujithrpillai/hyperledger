# Prometheus for Hyperledger monitoring
This document explains how to setup a Prometheus in a kubernetes environment for monitoring Hyperledger fabric

### Prerequisites & Dependencies
The configuration explained here is with a Kubernetes 1.18 version. It is expected to have a running kubernetes environment. The documentation doesnt explain setting up the persistent volumes, if data need to be preserved.
The `kube-state-metrics` is configured on the cluster, if kubernetes monitoring need to be done.
A namespace named `monitoring` is available. (The configurations below uses that namespace. If it need to be deployed in any other  namespace, the configurations given below need to be modified.)
### Creating necessary access
Create a file `clusterRole.yaml` with the following content,   
(A sample is available here : https://github.com/sujithrpillai/hyperledger/blob/master/prometheus/clusterRole.yaml)
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
  namespace: monitoring
rules:
- apiGroups: [""]
  resources:
  - nodes
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  verbs: ["get"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
```
Apply the configuration,
```
kubectl apply -f ./clusterRole.yaml
```
Create a file `serviceAccount.yaml` with the  following content,   
(A sample is available here: https://github.com/sujithrpillai/hyperledger/blob/master/prometheus/serviceAccount.yaml)
```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: monitoring
```
Apply the configuration,
```
kubectl apply -f ./serviceAccount.yaml
```
Create a file `clusterRoleBinding.yaml` with the following content,  
(A sample is available here: https://github.com/sujithrpillai/hyperledger/blob/master/prometheus/clusterRoleBinding.yaml)
```
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus
  namespace: monitoring
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
```
Create the prometheus configuration file `prometheus.yml` with the following content,  
(A sample is available here: https://github.com/sujithrpillai/hyperledger/blob/master/prometheus/prometheus.yml)
```
global:
  scrape_interval: 15s
# Scraping Prometheus itself
scrape_configs:
- job_name: 'Prometheus'
  static_configs:
  - targets: ['prometheus-service:9090']
# Scraping Kubernetes State Metrics
- job_name: 'Kube-state-metrics'
  static_configs:
    - targets: ['kube-state-metrics.kube-system.svc:8080']
```
Create a configmap with the above configuration file, 
```
```