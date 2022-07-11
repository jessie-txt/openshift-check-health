#!/bin/bash

list_node=$(oc get node | awk '{print $1}' | tail -n+2 | awk '{print $1}')
now=$(date +"%m_%d_%Y")
folder_now=$(mkdir -p $(pwd)/pm_log/$now)
DATE=date


output(){
    echo -e "\n===============================================\nProject: $PROJECT\nSecret: $SECRET \nCertificate File: $CERT \nCreated at: $($DATE -d @$START_EPOCH +'%d-%m-%Y %H:%M:%S') \nExpired after: $($DATE -d @$END_EPOCH +'%d-%m-%Y %H:%M:%S') \nDay remaining $DAY_REMAIN"
}  


outputMenus4(){
    oc get secrets -A -o go-template='{{range .items}}{{if eq .type "kubernetes.io/tls"}}{{.metadata.namespace}}{{" "}}{{.metadata.name}}{{" "}}{{index .data "tls.crt"}}{{"\n"}}{{end}}{{end}}' | while read namespace name cert; do echo -en "$namespace\t$name\t"; echo $cert | base64 -d | openssl x509 -noout -enddate; done | column -t >> $(pwd)/pm_log/$now/all_cert_$now.txt 
}  


quit(){
    printf "\rLoading..." 
    sleep 3
    printf "\rCopyright 2022 by Re..." 
    sleep 2
    exit 0

}


function one(){
    get_node=$(oc get node)
    get_co=$(oc get co)
    get_mcp=$(oc get mcp)
    get_cv=$(oc get clusterversion)
    top_node=$(oc adm top node --use-protocol-buffers=true)
    count_node=$(oc get node | awk '{print $1}' | tail -n+2 | wc | awk '{print $1}')
    cluster_id=$(oc get clusterversion -o jsonpath='{.items[].spec.clusterID}{"\n"}')
        echo -e "\nCluster OCP total node had $count_node nodes with Cluster ID $cluster_id\n\n===================\nNode\n===================\n$get_node\n\n===================\nCluster Operator\n===================\n$get_co\n\n===================\nMCP\n===================\n$get_mcp\n\n===================\nCluster Version\n===================\n$get_cv\n\n===================\nTop Node\n===================\n$top_node" >> $(pwd)/pm_log/$now/health_$now.txt
        echo -e "\nCluster OCP total node had $count_node nodes with Cluster ID $cluster_id\n\n===================\nNode\n===================\n$get_node\n\n===================\nCluster Operator\n===================\n$get_co\n\n===================\nMCP\n===================\n$get_mcp\n\n===================\nCluster Version\n===================\n$get_cv\n\n===================\nTop Node\n===================\n$top_node"
}

function two(){
    echo "$list_node" > $(pwd)/pm_log/list_node 
    folder_two=$(mkdir -p $(pwd)/pm_log/$now/node)
    du=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i df -h ; echo -e "=========================";done;)
    lsblck=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i lsblk ; echo  "=========================";done;)
    mem=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i free -h ; echo -e "=========================";done;)
    cpu=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i nproc ; echo -e "=========================";done;)
    upt=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i uptime; echo -e "=========================";done;)
        echo -e "\nDisk Usage\n\n $du \n\n\n  List Block Devices\n\n $lsblck CPU\n $cpu \n\n\n Memory\n\n $mem \n\n\n Uptime\n\n\n $upt " >> $(pwd)/pm_log/$now/node/node_ultz_$now.txt
        echo -e "\nDisk Usage\n\n $du \n\n\n  List Block Devices\n\n $lsblck CPU\n $cpu \n\n\n Memory\n\n $mem \n\n\n Uptime\n\n\n $upt" 
} 

function three(){
    check(){
        if [[ $SECRET =~ ^$1 ]];
            then
                NOT_ACTIVE=0
                if [ $ELAPSED_DAY -lt $2 ];
                then
                PRINT=0
                fi
            fi
    }      
    NOW_EPOCH=$($DATE +"%s")	
    for PROJECT in $(oc get projects --no-headers|grep 'openshift-'|awk '{print $1}')
    do
        for SECRET in $(oc get secret -n $PROJECT --no-headers|awk '{print $1}'|sort)
        do
            for CERT in $(oc get secrets/$SECRET -n $PROJECT -o yaml | grep 'tls.crt' | grep -v "f:"|awk -F":" '{print $1}')
            do
                END_DATE=$(oc get secrets/$SECRET -n $PROJECT \
                -o template='{{index .data "'$CERT'"}}' \
                | base64 -d \
                | openssl x509 -noout -enddate| awk -F'notAfter=' '{print $2}')
                START_DATE=$(oc get secrets/$SECRET -n $PROJECT \
                -o template='{{index .data "'$CERT'"}}' \
                | base64 -d \
                | openssl x509 -noout -startdate| awk -F'notBefore=' '{print $2}')

                END_EPOCH=$($DATE --date="${END_DATE}" +"%s")
                START_EPOCH=$($DATE --date="${START_DATE}" +"%s")
                DIFF=$(expr $END_EPOCH - $NOW_EPOCH)
                DAY_REMAIN=$(expr $DIFF / 86400)
                CREATE_DATE=$(oc get secret/$SECRET -n $PROJECT -o jsonpath='{.metadata.creationTimestamp}')
                CREATE_EPOCH=$($DATE --date="${CREATE_DATE}" +"%s")
                ELAPSED=$(expr $NOW_EPOCH - $CREATE_EPOCH)
                ELAPSED_DAY=$(expr $ELAPSED / 86400)
                PRINT=1
                NOT_ACTIVE=1
                # check for cert with 30 days automatically rotate
                check kube-scheduler-client-cert-key 30
                check kubelet-client 30
                check kube-controller-manager-client-cert-key 30
                check kube-apiserver-cert-syncer-client-cert-key 30
                if [ $NOT_ACTIVE -eq 0 ];
                then
                    if [ $PRINT -eq 0 ];
                    then
                        output $1
                    fi
                else
                    output $1
                fi
            done
        done
    done
}  


function four(){
    outputMenus4
    echo -e "NAMESPACE\tNAME\tEXPIRY" && oc get secrets -A -o go-template='{{range .items}}{{if eq .type "kubernetes.io/tls"}}{{.metadata.namespace}}{{" "}}{{.metadata.name}}{{" "}}{{index .data "tls.crt"}}{{"\n"}}{{end}}{{end}}' | while read namespace name cert; do echo -en "$namespace\t$name\t"; echo $cert | base64 -d | openssl x509 -noout -enddate; done | column -t
}

function five(){
    echo "$list_node" > $(pwd)/pm_log/list_node
    img_prune=$(for i in  $(cat pm_log/list_node); do echo -e  $i "=\n" ; ssh core@$i sudo podman system prune -a -f ; echo -e "=========================";done;)
    echo "Prune Unused Old Image on All Nodes"
    echo "$img_prune"
}


show_menus() {
   echo "~~~~~~~~~~~~~~~~~~~~~"   
   echo " M A I N - M E N U"
   echo "       by Re         "
   echo "~~~~~~~~~~~~~~~~~~~~~"
   echo -e "1. Check Global Health Cluster (Readiness Node; Cluster Operator;\n   MCP; Cluster Version; Top Usage Nodes)"
   echo -e "2. Check Resource Utilization on Every Node  (CPU, Memory, Disk Usage,\n   Block Device , Uptime ; default user: core)"
   echo "3. Check Expired Certificate on Namespace OpenShift-* (only display)"
   echo "4. Check List All Expired Certificate on OpenShift Cluster"
   echo "5. Prune Unused images on Every Node"
   echo "6. Exit"
}
read_options(){
   local choice
   read -p "Enter choice [ 1 - 6] " choice
   case $choice in
       1) one ;;
       2) two ;;
       3) three ;;
       4) four ;;
       5) five ;;
       6) quit 0;;
      
       *) echo -e "Error..." && WrongCommand;;
   esac
}

show_menus
read_options
