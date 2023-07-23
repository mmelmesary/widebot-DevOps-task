resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: acme-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory 
    email: myemail@example.com
    privateKeySecretRef:
      name: letsencrypt
    solvers:
    - dns01:
        route53:
          hostedZoneID: Z01235353GBP3H7HBOL24
          region: us-east-1
      selector:
        dnsZones:
        - "widebotapp.com"
    - http01:
        ingress:
          class: alb
YAML
}