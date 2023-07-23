resource "kubect_manifest" "app" {
  yaml_body= <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: my-webapp

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  namespace: my-webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
        - name: webapp
          image: cedricclyburn/mern-k8s-front
          ports:
            - containerPort: 80
          env:
            - name: DB_HOST
              value: mongodb-service
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
            - name: SQL_SERVER_HOST
              value: sql-server-service
            - name: SQL_SERVER_PORT
              value: "1433"
            - name: SQL_SERVER_DB_NAME
              value: root
            - name: SQL_SERVER_USERNAME
              value: <sql-server-username>
            - name: SQL_SERVER_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: sql-server-secret
                  key: password
            - name: REDIS_HOST
              value: redis-service
            - name: REDIS_PORT
              value: "6379"
          # Add additional environment variables as needed
      # Add additional containers, volumes, and configMaps as needed
          
---

apiVersion: v1
kind: Service
metadata:
  name: webapp-service
  namespace: my-webapp
  annotations:
    kubernetes.io/ingress.class: alb
    cert-manager.io/cluster-issuer: acme-issuer
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  selector:
    app: webapp
  ports:
    - name: http
      port: 80
      targetPort: 80
  type: LoadBalancer

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb-statefulset
  namespace: my-webapp
spec:
  serviceName: mongodb-service
  replicas: 3
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
        - name: mongodb
          image: mongo:4.4
          env:
            - name: MONGO_INITDB_ROOT_USERNAME
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: username
            - name: MONGO_INITDB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mongodb-secret
                  key: password
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongodb-data
              mountPath: /data/db
    volumeClaimTemplates:
    - metadata:
        name: sql-server-data
      spec:
        accessModes: 
        - ReadWriteOnce
        storageClassName: ebs-mongodb-storage
        resources:
          requests:
            storage: 1Gi

---

apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: my-webapp
spec:
  clusterIP: None
  selector:
    app: mongodb
  ports:
    - name: mongodb
      port: 27017

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sql-server-statefulset
  namespace: my-webapp
spec:
  serviceName: sql-server-service
  replicas: 3
  selector:
    matchLabels:
      app: sql-server
  template:
    metadata:
      labels:
        app: sql-server
    spec:
      containers:
        - name: sql-server
          image: mcr.microsoft.com/mssql/server:2019-latest
          env:
            - name: ACCEPT_EULA
              value: "Y"
            - name: MSSQL_SA_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: sql-server-secret
                  key: password
            - name: MSSQL_PID
              value: "Developer"
          ports:
            - containerPort: 1433
          volumeMounts:
            - name: sql-server-data
              mountPath: /var/opt/mssql
    volumeClaimTemplates:
    - metadata:
        name: sql-server-data
      spec:
        accessModes: 
        - ReadWriteOnce
        storageClassName: ebs-sql-storage
        resources:
          requests:
            storage: 1Gi

---

apiVersion: v1
kind: Service
metadata:
  name: sql-server-service
  namespace: my-webapp
spec:
  clusterIP: None
  selector:
    app: sql-server
  ports:
    - name: sql-server
      port: 1433

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-deployment
  namespace: my-webapp
spec:
  replicas: 2
  selector:
   matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
        - name: redis
          image: redis:latest
          ports:
            - containerPort: 6379
          # Add additional configuration as needed
      # Add additional containers, volumes, and configMaps as needed

---

apiVersion: v1
kind: Service
metadata:
  name: redis-service
  namespace: my-webapp
spec:
  selector:
    app: redis
  ports:
    - name: redis
      port: 6379

---

apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: my-webapp
type: Opaque
data:
  username: cm9vdGxvZ2lu
  password: cm9vdHBhc3N3b3Jk

---

apiVersion: v1
kind: Secret
metadata:
  name: sql-server-secret
  namespace: my-webapp
type: Opaque
data:
  password: cm9vdHBhc3N3b3Jk

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: my-webapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi

---

apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-mongodb-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer 

---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sql-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
reclaimPolicy: Delete
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer 
YAML
}

