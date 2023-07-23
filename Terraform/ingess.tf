resource "kubectl_manifest" "alb_ingress" {
    yaml_body =<<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  ingressClassName: nginx
  rules:
  - host: aspnetnetapp.widebotapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 80
  tls:
    - hosts:
      - aspnetnetapp.widebotapp.com
      secretName: tls-secret
YAML 
}