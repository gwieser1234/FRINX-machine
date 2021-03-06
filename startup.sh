#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd ${DIR}

# Common functions
script="startup.sh"

function example {
    echo -e "example: $script -m"
}

function usage {  
 echo -e "usage: $script [OPTION]  \n"  
}

function help {
  usage
    echo -e "OPTION:"
    echo -e "  -m | --minimal   Start with lower resource usage."
    echo -e "  -s | --skip      Skips healthchecks and check for execution errors."
    echo -e "\n"
  example
}

function check_success {
  if [[ $? -ne 0 ]] 
  then
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}System is not healthy. Shutting down.\n${NC}"
  echo "Removing containers."
  ./teardown.sh
  exit
fi
}

function start_container {
if [ "$minimal" = true ]; then
  sudo docker-compose -f docker-compose.yml -f docker-compose.min.yml up -d "$1"
else
  sudo docker-compose -f docker-compose.yml up -d "$1"
fi
}

function start_containers {
local containers_to_start=("odl" "dynomite" "elasticsearch" "kibana" "conductor-server" "frinxit" "micros"  "conductor-ui" "sample-topology" )

for i in "${containers_to_start[@]}"; do 

start_container $i
if [ "$skip" = false ]; then
  ./health_check.sh $i
  check_success $?
fi
echo "################"
done

}

function import_workflows {

sudo docker exec -it micros bash -c "cd /home/app && newman run netinfra_utils/postman.json --folder 'SETUP' -e netinfra_utils/postman_environment.json"
if [ "$skip" = false ]; then
  check_success $?
fi

}


# Loop arguments
minimal=false
skip=false
import=false
while [ "$1" != "" ];
do
case $1 in
    -m | --minimal)
    minimal=true
    shift
    ;;
    -s | --skip)
    skip=true
    shift
    ;;
    -h | --help )
    help
    exit
    ;;
    *)    # unknown option
    echo "$script: illegal option $1"
    exit 1 #error
    ;;
esac
done


# Starts containers
start_containers

# Imports workflows
import_workflows


echo 'Startup finished!'





