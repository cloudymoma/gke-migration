File="projects.txt"
projects=$(cat $File)
for line in $projects
do
    echo $line
    mkdir $line
    cd $line
    gcloud config set project $line
    
    i=$((0))
    for n in $(gcloud container clusters list --format="value(NAME, LOCATION)")
    do 
        if (( $i < 1 )); then
            cluster_name=$n
            echo "cluster name: ${cluster_name}"
            i=$(($i+1))
        elif (( $i < 2 )); then
            localtion=$n
            echo "cluster location: ${localtion}"
            i=$((0))
            gcloud container clusters get-credentials $cluster_name --zone $localtion
            context=$(kubectl config current-context)
            mkdir -p $context
            cd $context
                j=$((0))
                for m in $(kubectl get -o=custom-columns=NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name pv,pvc,configmap,ingress,service,secret,deployment,statefulset,hpa,job,cronjob --all-namespaces | grep -v 'secrets/default-token')
                do
                    if (( $j < 1 )); then
                        namespace=$m
                        j=$(($j+1))
                        if [[ "$namespace" == "PersistentVolume" ]]; then
                            kind=$m
                            j=$(($j+1))
                        fi
                    elif (( $j < 2 )); then
                        kind=$m
                        j=$(($j+1))
                    elif (( $j < 3 )); then
                        name=$m
                        j=$((0))
                        if [[ ("$namespace" != "NAMESPACE") && ("$namespace" != "kube-"*)  ]]; then
                            mkdir -p $namespace

                            yaml=$((kubectl get $kind -o=yaml $name -n $namespace ) 2>/dev/null)
                            if [[ $kind != 'Secret' || $yaml != *"type: kubernetes.io/service-account-token"* ]]; then
                                echo "Saving ${namespace}/${kind}.${name}.yaml"
                                kubectl get $kind $name -oyaml -n $namespace > $namespace/$kind.$name.yaml
                            fi
                        fi
                    fi
                done
            cd ..
        fi
    done
    cd ..
done