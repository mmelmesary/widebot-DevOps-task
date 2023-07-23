resource "kubectl_manifest" "cert-certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: certificate
  namespace: default
spec:
  secretName: tls-secret
  issuerRef:
    name: acme-issuer
    kind: ClusterIssuer
  dnsNames:
    - aspnetapp.widebotapp.com
YAML
}