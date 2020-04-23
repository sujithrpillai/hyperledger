# Prometheus for Hyperledger monitoring
This document explains how to setup a Prometheus in a kubernetes environment for monitoring Hyperledger fabric

### Prerequisites & Dependencies
The configuration explained here is with a Kubernetes 1.18 version. It is expected to have a running kubernetes environment. The documentation doesnt explain setting up the persistent volumes, if data need to be preserved.
The `kube-state-metrics` is configured on the cluster, if kubernetes monitoring need to be done.
A namespace named `monitoring` is available. (The configurations below uses that namespace. If it need to be deployed in any other  namespace, the configurations given below need to be modified.)
### Creating necessary access
Create a file `clusterRole.yaml` with the following content,   
(A sample is available [here](clusterRole.yaml))
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
(A sample is available [here](serviceAccount.yaml))
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
(A sample is available [here](clusterRoleBinding.yaml))
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
(A sample is available [here](prometheus.yml))
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
# Scraping Orderer Metrics (Replace the Target Hostname and Port according to the environment)
- job_name: 'Orderer'
  static_configs:
    - targets: ['hyperledger:9444']
# Scraping Org1 Peer Metrics (Replace the Target Hostname and Port according to the environment)
- job_name: 'Peer-Org1'
  static_configs:
    - targets: ['hyperledger:9445']
# Scraping Org2 Peer Metrics (Replace the Target Hostname and Port according to the environment)
- job_name: 'Peer-Org2'
  static_configs:
    - targets: ['hyperledger:9446']
```
Create a configmap with the above configuration file, 
```
kubectl create configmap prometheus-config --from-file=./prometheus.yml -n monitoring
```
Create a file `prometheus-deployment.yaml` with the following content,  
(A sample is available [here](prometheus-deployment.yaml))
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus-deployment
  namespace: monitoring
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus-cont
        image: prom/prometheus
        volumeMounts:
        - name: config-volume
          mountPath: /etc/prometheus/prometheus.yml
          subPath: prometheus.yml
        ports:
        - containerPort: 9090
      volumes:
      - name: config-volume
        configMap:
          name: prometheus-config
      serviceAccountName: prometheus
```
Apply the configuration,
```
kubectl apply -f ./prometheus-deployment.yaml
```
Create a file `prometheus-service.yaml` with the following content,  
(A sample is available [here](prometheus-service.yaml))
```
kind: Service
apiVersion: v1
metadata:
  name: prometheus-service
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - name: promui
    nodePort: 30900
    protocol: TCP
    port: 9090
    targetPort: 9090
  type: NodePort
```
Now the prometheus application is available on port 30900 of the kubernetes worker node.

If you make any changes to the configuration files, re-deploy the application with the help of following commands,  
(These commands are available [here](runPrometheus.sh)
```
kubectl delete configmap prometheus-config -n monitoring
kubectl delete -f prometheus-deployment.yaml 
kubectl create configmap prometheus-config --from-file=./prometheus.yml -n monitoring
kubectl create -f prometheus-deployment.yaml 
```