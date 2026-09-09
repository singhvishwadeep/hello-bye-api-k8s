minikube start --driver=docker
kubectl get nodes
kubectl create namespace hello-bye
kubectl get namespace
vi hello-bye-pod.yaml
apiVersion: v1
kind: Pod

metadata:
  name: hello-bye-pod
  namespace: hello-bye
  labels:
    app: hello-bye

spec:
  containers:

    - name: hello-api
      image: vsdpsingh/hello-api:1.0
      imagePullPolicy: Always
      ports:
        - containerPort: 5000

    - name: bye-api
      image: vsdpsingh/bye-api:1.0
      imagePullPolicy: Always
      ports:
        - containerPort: 6000

kubectl apply -f hello-bye-pod.yaml
$ kubectl get pods -n hello-bye
NAME            READY   STATUS    RESTARTS   AGE
hello-bye-pod   2/2     Running   0          59s

#check logs - 
$ kubectl logs hello-bye-pod -n hello-bye -c hello-api
 * Serving Flask app 'app'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://10.244.0.3:5000
Press CTRL+C to quit
$ kubectl logs hello-bye-pod -n hello-bye -c bye-api
 * Serving Flask app 'app'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:6000
 * Running on http://10.244.0.3:6000
Press CTRL+C to quit

#login to container
kubectl exec -it hello-bye-pod -n hello-bye -c hello-api -- sh
kubectl exec -it hello-bye-pod -n hello-bye -c bye-api -- sh

#describe the pods
kubectl describe pod hello-bye-pod -n hello-bye

#delete the pod
kubectl delete pod hello-bye-pod -n hello-bye

# till here it is simple pod, lets create these using deployment and service

vi hello-bye-deployment.yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: hello-bye
  namespace: hello-bye

spec:
  replicas: 4

  selector:
    matchLabels:
      app: hello-bye

  template:
    metadata:
      labels:
        app: hello-bye

    spec:
      containers:

        - name: hello-api
          image: vsdpsingh/hello-api:1.0
          imagePullPolicy: Always
          ports:
            - containerPort: 5000

        - name: bye-api
          image: vsdpsingh/bye-api:1.0
          imagePullPolicy: Always
          ports:
            - containerPort: 6000

kubectl apply -f hello-bye-deployment.yaml
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployments -n hello-bye
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
hello-bye   4/4     4            4           25s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get replicasets -n hello-bye
NAME                  DESIRED   CURRENT   READY   AGE
hello-bye-ddbd58cbf   4         4         4       42s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS    RESTARTS   AGE
hello-bye-ddbd58cbf-5b59t   2/2     Running   0          55s
hello-bye-ddbd58cbf-g99f5   2/2     Running   0          55s
hello-bye-ddbd58cbf-qlpph   2/2     Running   0          55s
hello-bye-ddbd58cbf-vxk8p   2/2     Running   0          55s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployment,replicaset,pod -n hello-bye
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-bye   4/4     4            4           85s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-bye-ddbd58cbf   4         4         4       85s

NAME                            READY   STATUS    RESTARTS   AGE
pod/hello-bye-ddbd58cbf-5b59t   2/2     Running   0          85s
pod/hello-bye-ddbd58cbf-g99f5   2/2     Running   0          85s
pod/hello-bye-ddbd58cbf-qlpph   2/2     Running   0          85s
pod/hello-bye-ddbd58cbf-vxk8p   2/2     Running   0          85s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 


#now create hello service
vi hello-service.yaml
apiVersion: v1
kind: Service

metadata:
  name: hello-service
  namespace: hello-bye

spec:
  selector:
    app: hello-bye

  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000

  type: ClusterIP

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl apply -f hello-service.yaml 
service/hello-service created
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get svc -n hello-bye
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
hello-service   ClusterIP   10.110.123.85   <none>        5000/TCP   24s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get endpoints hello-service -n hello-bye
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME            ENDPOINTS                                                     AGE
hello-service   10.244.0.4:5000,10.244.0.5:5000,10.244.0.6:5000 + 1 more...   2m2s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get endpointslice -n hello-bye
NAME                  ADDRESSTYPE   PORTS   ENDPOINTS                                      AGE
hello-service-jxwsb   IPv4          5000    10.244.0.5,10.244.0.4,10.244.0.6 + 1 more...   3m15s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl run curl-client \
  -n hello-bye \
  --image=curlimages/curl \
  --restart=Never \
  -it --rm \
  -- sh
curl http://hello-service:5000/hello
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
~ $ curl http://hello-service:5000/hello
{"pod_name":"hello-bye-ddbd58cbf-5b59t","status":"hello"}
~ $ for i in $(seq 1 20); do
>   curl -s http://hello-service:5000/hello
>   echo
> done
{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-vxk8p","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-5b59t","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-5b59t","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-5b59t","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-5b59t","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-vxk8p","status":"hello"}

{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}

~ $ 


vi bye-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: bye-service
  namespace: hello-bye
spec:
  selector:
    app: hello-bye
  ports:
    - protocol: TCP
      port: 6000
      targetPort: 6000
  type: ClusterIP

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl apply -f bye-service.yaml
service/bye-service created
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get svc -n hello-bye
NAME            TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
bye-service     ClusterIP   10.108.168.42   <none>        6000/TCP   13s
hello-service   ClusterIP   10.110.123.85   <none>        5000/TCP   9m21s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl run curl-client \
  -n hello-bye \
  --image=curlimages/curl \
  --restart=Never \
  -it --rm \
  -- sh
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
~ $ curl http://bye-service:6000/bye
{"pod_name":"hello-bye-ddbd58cbf-g99f5","status":"bye"}
~ $ curl http://hello-service:5000/hello
{"pod_name":"hello-bye-ddbd58cbf-qlpph","status":"hello"}
~ $ exit


# increasing the number of pods to 6 (hence 6 replicas = 6 x 2 = 12 containers)
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl scale deployment hello-bye --replicas=6 -n hello-bye
deployment.apps/hello-bye scaled
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS              RESTARTS   AGE
hello-bye-ddbd58cbf-29bpt   0/2     ContainerCreating   0          7s
hello-bye-ddbd58cbf-5b59t   2/2     Running             0          16m
hello-bye-ddbd58cbf-g99f5   2/2     Running             0          16m
hello-bye-ddbd58cbf-qlpph   2/2     Running             0          16m
hello-bye-ddbd58cbf-vxk8p   2/2     Running             0          16m
hello-bye-ddbd58cbf-zkj8v   0/2     ContainerCreating   0          7s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS    RESTARTS   AGE
hello-bye-ddbd58cbf-29bpt   2/2     Running   0          11s
hello-bye-ddbd58cbf-5b59t   2/2     Running   0          16m
hello-bye-ddbd58cbf-g99f5   2/2     Running   0          16m
hello-bye-ddbd58cbf-qlpph   2/2     Running   0          16m
hello-bye-ddbd58cbf-vxk8p   2/2     Running   0          16m
hello-bye-ddbd58cbf-zkj8v   2/2     Running   0          11s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

# now we have 6 end points for each
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get endpoints hello-service bye-service -n hello-bye
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME            ENDPOINTS                                                       AGE
hello-service   10.244.0.11:5000,10.244.0.12:5000,10.244.0.4:5000 + 3 more...   13m
bye-service     10.244.0.11:6000,10.244.0.12:6000,10.244.0.4:6000 + 3 more...   4m49s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

# Architecture
                    Deployment
                    hello-bye
                        │
          ┌─────────────┼─────────────┐
          │             │             │
        Pod 1         Pod 2         ... Pod 6
          │             │                 │
     ┌────┴────┐   ┌────┴────┐       ┌────┴────┐
     │ hello   │   │ hello   │       │ hello   │
     │ :5000   │   │ :5000   │       │ :5000   │
     │ bye     │   │ bye     │       │ bye     │
     │ :6000   │   │ :6000   │       │ :6000   │
     └─────────┘   └─────────┘       └─────────┘
          │             │                 │
          └─────────────┼─────────────────┘
                        │
             ┌──────────┴──────────┐
             │                     │
      hello-service          bye-service
        :5000                   :6000


# deleting one pod, and new one will come automatically
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl delete pod hello-bye-ddbd58cbf-5b59t -n hello-bye
pod "hello-bye-ddbd58cbf-5b59t" deleted from hello-bye namespace
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS    RESTARTS   AGE
hello-bye-ddbd58cbf-29bpt   2/2     Running   0          3m47s
hello-bye-ddbd58cbf-bcvfg   2/2     Running   0          44s
hello-bye-ddbd58cbf-g99f5   2/2     Running   0          19m
hello-bye-ddbd58cbf-qlpph   2/2     Running   0          19m
hello-bye-ddbd58cbf-vxk8p   2/2     Running   0          19m
hello-bye-ddbd58cbf-zkj8v   2/2     Running   0          3m47s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

# IMPORTANT
Deployment
    │
    │ manages
    ▼
ReplicaSet
    │
    │ maintains desired number
    ▼
Pods
    │
    ├── hello-api container
    └── bye-api container

So the Deployment doesn't directly run your containers. It manages the ReplicaSet, which maintains the Pods.


#scaling down to 2 pods
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl scale deployment hello-bye --replicas=2 -n hello-bye
deployment.apps/hello-bye scaled
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS        RESTARTS   AGE
hello-bye-ddbd58cbf-29bpt   2/2     Terminating   0          6m3s
hello-bye-ddbd58cbf-bcvfg   2/2     Terminating   0          3m
hello-bye-ddbd58cbf-g99f5   2/2     Running       0          21m
hello-bye-ddbd58cbf-qlpph   2/2     Running       0          21m
hello-bye-ddbd58cbf-vxk8p   2/2     Terminating   0          21m
hello-bye-ddbd58cbf-zkj8v   2/2     Terminating   0          6m3s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get pods -n hello-bye
NAME                        READY   STATUS    RESTARTS   AGE
hello-bye-ddbd58cbf-g99f5   2/2     Running   0          22m
hello-bye-ddbd58cbf-qlpph   2/2     Running   0          22m
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployment,replicaset,pod -n hello-bye
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-bye   2/2     2            2           23m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-bye-ddbd58cbf   2         2         2       23m

NAME                            READY   STATUS    RESTARTS   AGE
pod/hello-bye-ddbd58cbf-g99f5   2/2     Running   0          23m
pod/hello-bye-ddbd58cbf-qlpph   2/2     Running   0          23m
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 


Both Pods have this: hello-bye-ddbd58cbf

in their names:
    hello-bye-ddbd58cbf-g99f5
    hello-bye-ddbd58cbf-qlpph

hello-bye = Deployment name.
ddbd58cbf = ReplicaSet identifier.
g99f5 / qlpph = unique Pod identifiers.


# change image to hello-api:2.0 and bye-api:2.0
change deployment.yaml
image: vsdpsingh/hello-api:2.0
image: vsdpsingh/bye-api:2.0

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl apply -f hello-bye-deployment.yaml 
deployment.apps/hello-bye configured
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl rollout status deployment/hello-bye -n hello-bye
Waiting for deployment "hello-bye" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "hello-bye" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-bye" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-bye" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "hello-bye" rollout to finish: 3 of 4 updated replicas are available...
deployment "hello-bye" successfully rolled out
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployment,replicaset,pod -n hello-bye
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-bye   4/4     4            4           80m

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-bye-74bc9c6489   4         4         4       33s
replicaset.apps/hello-bye-ddbd58cbf    0         0         0       80m

NAME                             READY   STATUS        RESTARTS   AGE
pod/hello-bye-74bc9c6489-fss8q   2/2     Running       0          33s
pod/hello-bye-74bc9c6489-j5wbv   2/2     Running       0          32s
pod/hello-bye-74bc9c6489-nnsfc   2/2     Running       0          14s
pod/hello-bye-74bc9c6489-wcmr2   2/2     Running       0          10s
pod/hello-bye-ddbd58cbf-g99f5    2/2     Terminating   0          80m
pod/hello-bye-ddbd58cbf-qlpph    2/2     Terminating   0          80m
pod/hello-bye-ddbd58cbf-rg6wq    2/2     Terminating   0          33s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl get deployment,replicaset,pod -n hello-bye
NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-bye   4/4     4            4           81m

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/hello-bye-74bc9c6489   4         4         4       75s
replicaset.apps/hello-bye-ddbd58cbf    0         0         0       81m

NAME                             READY   STATUS    RESTARTS   AGE
pod/hello-bye-74bc9c6489-fss8q   2/2     Running   0          75s
pod/hello-bye-74bc9c6489-j5wbv   2/2     Running   0          74s
pod/hello-bye-74bc9c6489-nnsfc   2/2     Running   0          56s
pod/hello-bye-74bc9c6489-wcmr2   2/2     Running   0          52s
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
# we now have 2.0 version
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ ./test-api.sh 
Handling connection for 5000
{"pod_name":"hello-bye-74bc9c6489-fss8q","status":"hello 2.0"}
Handling connection for 5000
{"pod_name":"hello-bye-74bc9c6489-fss8q","status":"hello-healthy 2.0"}
Handling connection for 6000
{"pod_name":"hello-bye-74bc9c6489-fss8q","status":"bye 2.0"}
Handling connection for 6000
{"pod_name":"hello-bye-74bc9c6489-fss8q","status":"bye-healthy 2.0"}
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$


# for rollback
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl rollout history deployment/hello-bye -n hello-bye
deployment.apps/hello-bye 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 

#check the rollout description
vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl rollout history deployment/hello-bye --revision=1 -n hello-bye
deployment.apps/hello-bye with revision #1
Pod Template:
  Labels:	app=hello-bye
	pod-template-hash=ddbd58cbf
  Containers:
   hello-api:
    Image:	vsdpsingh/hello-api:1.0
    Port:	5000/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
   bye-api:
    Image:	vsdpsingh/bye-api:1.0
    Port:	6000/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
  Node-Selectors:	<none>
  Tolerations:	<none>

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ kubectl rollout history deployment/hello-bye --revision=2 -n hello-bye
deployment.apps/hello-bye with revision #2
Pod Template:
  Labels:	app=hello-bye
	pod-template-hash=74bc9c6489
  Containers:
   hello-api:
    Image:	vsdpsingh/hello-api:2.0
    Port:	5000/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
   bye-api:
    Image:	vsdpsingh/bye-api:2.0
    Port:	6000/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
  Node-Selectors:	<none>
  Tolerations:	<none>

vishwadeep@Ubuntu2604:~/Desktop/banking-services/single-pod-k8s-setup/k8s$ 
