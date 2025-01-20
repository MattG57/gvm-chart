kubectl cp reconfig.js mongo-for-aks-mongodb-0:/tmp/
kubectl exec -it mongo-for-aks-mongodb-0 -- mongosh admin --authenticationDatabase admin -u root -p 1I1uXCdaz6 --eval "load('/tmp/reconfig.js')"
