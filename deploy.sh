#!/bin/bash

# Name used to generate spec ID, should be unique
APPNAME=SMD_BS_ARD_ControlChart
# Name displayed to the users
APPDISPLAYNAME=SMD BS ARD Empower - Response Factors
# App description showin to the users
APPDESCRIPTION="Application for the monitoring of Empower3 response factors."
IMAGENAME=gcr.io/gred-ptddtalak-sb-001-e4372d8c/jktestapp
# Command to be passed to the image
IMAGECMD="[\"R\",\"-e\",\"shiny::runApp('/root/app',port=3838,host='0.0.0.0')\"]"

CLUSTERNAME=dlab-gen-cluster1
SPDEPLOYMENTNAME=sproxy

# Step 1 Docker Build
echo ============================
echo Start Docker build...
echo ============================
sudo docker build --no-cache -t $IMAGENAME .

# Step 2: Upload container to GCP
echo ============================
echo Uploading container to GCP...
echo ============================
sudo docker push $IMAGENAME

# Step 3: Delete Images to free space
echo ============================
echo Deleting images from local
echo ============================
sudo docker image rm $IMAGENAME
echo ============================
echo Deleting images from GCR
echo ============================
for digest in $(gcloud container images list-tags $IMAGENAME --filter='-tags:*' --format='get(digest)')
do
  (
    gcloud container images delete -q --force-delete-tags "${IMAGENAME}@${digest}"
  )
done

# Step 4: Confirm upload
echo ============================
echo Checking upload...
echo ============================
gcloud container images list-tags $IMAGENAME


# Step 5: Check if it's a new application and add it to shinyproxy if true
echo ============================
echo Generating specs...
echo ============================
echo "  - id: "$APPNAME>spec.txt
echo "    display-name: "$APPDISPLAYNAME>>spec.txt
echo "    description: "$APPDESCRIPTION>>spec.txt
echo "    container-image: "$IMAGENAME>>spec.txt
# Uncomment container-cmd for shiny apps
#echo "    container-cmd: "$IMAGECMD>>spec.txt
echo ============================
echo Checking shinyproxy...
echo ============================
wget 'https://raw.github.roche.com/DataLab/shinyproxy/master/shinyproxy-example/application.yml'
git_push_flag=0
head -1 spec.txt>spec_head.txt
spec_match=$(grep -i -Fx -f spec_head.txt application.yml|sed '/^\s*#/d;/^\s*$/d'|wc -l)
if [[ "$spec_match" -eq 0 ]]
then
git clone git@github.roche.com:DataLab/shinyproxy.git
cd shinyproxy/shinyproxy-example
cat ../../spec.txt >> application.yml
git_push_flag=1
else
echo No new spec to be added
fi

# Step 6: Rollout image update to kubernetes cluster
echo ============================
echo Rollout to cluster...
echo ============================
# check if cluster exists
chk_clstr=$(gcloud container clusters list|grep -o $CLUSTERNAME|wc -l)
if [[ "$chk_clstr" -eq 0 ]]; then echo "Cluster not found, check name and try again."; exit 0; fi
# get cluster credentials
gcloud container clusters get-credentials $CLUSTERNAME --zone=us-west1-b
# run kubectl command, ignore the below two commented commands
# kubectl set image deployment/$SPDEPLOYMENTNAME shinyproxy=$IMAGENAME:latest
# kubectl set image deployment/$SPDEPLOYMENTNAME shinyproxy=$IMAGENAME
kubectl rollout restart deployment/$SPDEPLOYMENTNAME

# Step 7: Git push shinyproxy if flag is set
echo ============================
echo Pushing changes to shinyproxy...
echo ============================
# Make sure to enter your email and name here
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
if [[ "$git_push_flag" -eq 1 ]]
then 
git add application.yml
git commit -m"Jenkins adding new application $APPNAME to shinyproxy"
git push
else
echo No push required.
fi

# Complete
echo ============================
echo Complete!
echo ============================