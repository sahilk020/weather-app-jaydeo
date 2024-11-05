#!/bin/bash

# Define Variables
TOMCAT_HOME="/opt/tomcat"         # Change to your Tomcat installation path
TOMCAT_LOG="$TOMCAT_HOME/logs/startup.log"
CODE_DEPOLY_APP="weather-deployment"
CODE_DEPLOY_GROUP="weather-deployment-group"
CODE_DEPLOY_ID="969c12b5-410a-444c-8f36-2f16bf4e185f"


#Get the deployment id
DEPLOYMENT_ID=$(aws deploy list-deployments --application-name $CODE_DEPOLY_APP --deployment-group-name $CODE_DEPLOY_GROUP --region ap-south-1 --query 'deployments[0]' --output text)
# Find all .war files in the deployment directory
WAR_FILES=$(find /opt/codedeploy-agent/deployment-root/$CODE_DEPLOY_ID/$DEPLOYMENT_ID/deployment-archive/ -name "*.war" -type f)




# Function to start Tomcat
start_tomcat() {
    echo "Starting Tomcat server..."

    # Check if Tomcat is already running
    PID=$(pgrep -f "$TOMCAT_HOME")
    if [ -n "$PID" ]; then
        echo "Tomcat is already running with PID $PID."
        exit 0
    fi

    # start the Tomcat service
    sudo  $TOMCAT_HOME/bin/startup.sh > $TOMCAT_LOG 2>&1

    if [ $? -eq 0 ]; then
        echo "Tomcat started successfully."
    else
        echo "Failed to start Tomcat. Check the logs at $TOMCAT_LOG for details."
        exit 1
    fi
}

# Function to verify that Tomcat has started
verify_tomcat() {
    echo "Checking if Tomcat is running..."
    
    sleep 5  # Wait a few seconds for Tomcat to start
    
    # Check if Tomcat is running by checking the process
    PID=$(pgrep -f "$TOMCAT_HOME")
    if [ -n "$PID" ]; then
        echo "Tomcat is running with PID $PID."
    else
        echo "Tomcat did not start properly. Please check the logs."
        exit 1
    fi
}



if [ -z "$WAR_FILES" ]; then
  echo "No WAR files found in the deployment archive."
  exit 1
fi

# Loop through each WAR file found and deploy it
for WAR_FILE in $WAR_FILES; do
  # Extract the WAR file name
  WAR_FILE_NAME=$(basename "$WAR_FILE")
  
  echo "Deploying WAR file: $WAR_FILE_NAME"

  # Move the WAR file to the Tomcat webapps directory
  cp "$WAR_FILE" /opt/tomcat/webapps/

  if [ $? -eq 0 ]; then
    echo "WAR file successfully deployed to /opt/tomcat/webapps/$WAR_FILE_NAME"
  else
    echo "Failed to deploy $WAR_FILE_NAME"
    exit 1
  fi
done

# Restart the Tomcat service to pick up the new WAR files

echo "All WAR files deployed"




# Export environment variables
export CATALINA_HOME=$TOMCAT_HOME
# Start and verify Tomcat
start_tomcat
verify_tomcat
