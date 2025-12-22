kubectl -n argocd apply  -f argo/echo/root.yaml
kubectl -n argocd delete -f argo/echo/root.yaml
kubectl -n argocd delete -f argo/echo/src/apps/app1.yaml