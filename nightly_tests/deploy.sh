#!/usr/bin/bash

STACK_NAME=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 --stack-name <cloudformation_stack_name>"
    exit 1
}

#
# It's mandatory to speciy a valid command arguments
#
if [[ $# -ne 2 ]]; then
  usage
fi

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Check if mandatory options are provided
if [[ -z $STACK_NAME ]]; then
    usage
fi

echo "STACK_NAME: ${STACK_NAME}"

export SSH_KEY="~/.ssh/ucs-nightly.pem"

export SSM_VPC_ID="/unity/testing/nightly/vpc-id"
export SSM_PUB_SUBNET1="/unity/testing/nightly/publicsubnet1"
export SSM_PUB_SUBNET2="/unity/testing/nightly/publicsubnet2"
export SSM_PRIV_SUBNET1="/unity/testing/nightly/privatesubnet1"
export SSM_PRIV_SUBNET2="/unity/testing/nightly/privatesubnet2"
export SSM_KEYPAIR_NAME="/unity/testing/nightly/keypairname"
export SSM_INSTANCE_TYPE="/unity/testing/nightly/instancetype"
export SSM_PRIVILEGED_POLICY="/unity/testing/nightly/privilegedpolicyname"
export SSM_GITHUB_TOKEN="/unity/testing/nightly/githubtoken"
export SSM_VENUE="/unity/testing/nightly/venue"
export SSM_ACCOUNT_NAME="/unity/testing/nightly/accountname"
#export STACK_NAME="unity-cs-nightly-management-console"


VPCID=$(aws ssm get-parameter                --name ${SSM_VPC_ID}            |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PublicSubnetID1=$(aws ssm get-parameter      --name ${SSM_PUB_SUBNET1}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PublicSubnetID2=$(aws ssm get-parameter      --name ${SSM_PUB_SUBNET2}       |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivateSubnetID1=$(aws ssm get-parameter     --name ${SSM_PRIV_SUBNET1}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivateSubnetID2=$(aws ssm get-parameter     --name ${SSM_PRIV_SUBNET2}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
InstanceType=$(aws ssm get-parameter         --name ${SSM_INSTANCE_TYPE}     |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
PrivilegedPolicyName=$(aws ssm get-parameter --name ${SSM_PRIVILEGED_POLICY} |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
GithubToken=$(aws ssm get-parameter          --name ${SSM_GITHUB_TOKEN}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
Venue=$(aws ssm get-parameter                --name ${SSM_VENUE}             |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
ACCOUNT_NAME=$(aws ssm get-parameter         --name ${SSM_ACCOUNT_NAME}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')
#KeyPairName=$(aws ssm get-parameter          --name ${SSM_KEYPAIR_NAME}      |grep '"Value":' |sed 's/^.*: "//' | sed 's/".*$//')

if [ -z "$VPCID" ] 
then 
    echo "ERROR: Could not read VPC ID from SSM.  Does the key [$SSM_VPC_ID] exist?"
    exit
fi
if [ -z "$PublicSubnetID1" ]
then
    echo "ERROR: Could not read Subnet ID from SSM.  Does the key [$SSM_PUB_SUBNET1] exist?"
    exit
fi
if [ -z "$PublicSubnetID2" ]
then
    echo "ERROR: Could not read Subnet ID from SSM.  Does the key [$SSM_PUB_SUBNET2] exist?"
    exit
fi
if [ -z "$PrivateSubnetID1" ]
then
    echo "ERROR: Could not read Subnet ID from SSM.  Does the key [$SSM_PRIV_SUBNET1] exist?"
    exit
fi
if [ -z "$PrivateSubnetID2" ]
then
    echo "ERROR: Could not read Subnet ID from SSM.  Does the key [$SSM_PRIV_SUBNET2] exist?"
    exit
fi
if [ -z "$InstanceType" ] 
then 
    echo "ERROR: Could not read Instance Type from SSM.  Does the key [$SSM_INSTANCE_TYPE] exist?"
    exit
fi
if [ -z "$PrivilegedPolicyName" ] 
then 
    echo "ERROR: Could not read Privileged Policy Name from SSM.  Does the key [$SSM_PRIVILEGED_POLICY] exist?"
    exit
fi
if [ -z "$GithubToken" ] 
then 
    echo "ERROR: Could not read Github Token from SSM.  Does the key [$SSM_GITHUB_TOKEN] exist?"
    exit
fi
if [ -z "$Venue" ] 
then 
    echo "ERROR: Could not read Venue from SSM.  Does the key [$SSM_VENUE] exist?"
    exit
fi
if [ -z "$ACCOUNT_NAME" ] 
then 
    echo "ERROR: Could not read Account Name from SSM.  Does the key [$SSM_ACCOUNT_NAME] exist?"
    exit
fi
#if [ -z "$KeyPairName" ] 
#then 
#    echo "ERROR: Could not read Key Pair Name from SSM.  Does the key [$SSM_KEYPAIR_NAME] exist?"
#    exit
#fi

aws cloudformation create-stack \
  --stack-name ${STACK_NAME} \
  --template-body file://template.yml \
  --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=VPCID,ParameterValue=${VPCID} \
    ParameterKey=PublicSubnetID1,ParameterValue=${PublicSubnetID1} \
    ParameterKey=PublicSubnetID2,ParameterValue=${PublicSubnetID2} \
    ParameterKey=PrivateSubnetID1,ParameterValue=${PrivateSubnetID1} \
    ParameterKey=PrivateSubnetID2,ParameterValue=${PrivateSubnetID2} \
    ParameterKey=InstanceType,ParameterValue=${InstanceType} \
    ParameterKey=PrivilegedPolicyName,ParameterValue=${PrivilegedPolicyName} \
    ParameterKey=GithubToken,ParameterValue=${GithubToken} \
    ParameterKey=Venue,ParameterValue=${Venue} \
  --tags Key=ServiceArea,Value=U-CS

#    ParameterKey=KeyPairName,ParameterValue=${KeyPairName} \

echo "Nightly Test in the $ACCOUNT_NAME account" >> nightly_output.txt
echo "STACK_NAME=$STACK_NAME">NIGHTLY.ENV

#echo"--------------------------------------------------------------------------[PASS]"
echo "Stack Name: [$STACK_NAME]" >> nightly_output.txt
echo "Stack Name: [$STACK_NAME]"


## Wait for startup
STACK_STATUS=""

WAIT_TIME=0
MAX_WAIT_TIME=2400
WAIT_BLOCK=20

while [ -z "$STACK_STATUS" ]
do
    #echo "Checking Stack Creation [${STACK_NAME}] Status after ${WAIT_TIME} seconds..." >> nightly_output.txt
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Waiting for Cloudformation Stack..........................................[$WAIT_TIME]"

    aws cloudformation describe-stacks --stack-name ${STACK_NAME} > status.txt
    STACK_STATUS=$(cat status.txt |grep '"StackStatus": \"CREATE_COMPLETE\"')
    sleep $WAIT_BLOCK
    WAIT_TIME=$(($WAIT_BLOCK + $WAIT_TIME))
    if [ "$WAIT_TIME" -gt "$MAX_WAIT_TIME" ] 
    then
        #echo"--------------------------------------------------------------------------[PASS]" 
        echo "Cloudformation Stack creation exceeded ${MAX_WAIT_TIME} seconds - [FAIL]" >> nightly_output.txt
        echo "Cloudformation Stack creation exceeded ${MAX_WAIT_TIME} seconds - [FAIL]"
        exit
    fi
done

STACK_STATUS=$(echo "${STACK_STATUS}" |sed 's/^.*: "//' |sed 's/".*//')

#echo "Final Stack Status: ${STACK_STATUS}" >> nightly_output.txt
#echo "Final Stack Status: ${STACK_STATUS}"

#echo"--------------------------------------------------------------------------[PASS]" 
echo "Stack Status (Final): [$STACK_STATUS]" >> nightly_output.txt
echo "Stack Status (Final): [$STACK_STATUS]"


if [ ! -z "$STACK_STATUS" ]
then 
    #echo"--------------------------------------------------------------------------[PASS]" 
    echo "Stack Creation Time: [${WAIT_TIME} seconds] - PASS" >> nightly_output.txt
    echo "Stack Creation Time: [${WAIT_TIME} seconds] - PASS"
fi

## This is where some stuff should go

## Get the information needed to connect to the new instance
#aws ec2 describe-instances --instance-id $INSTANCE_ID > status.txt
#IP_ADDRESS=$(grep PrivateIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
#echo "IP_ADDRESS=$IP_ADDRESS">>NIGHTLY.ENV

#IP_ADDRESS_PUBLIC=$(grep PublicIpAddress status.txt |sed 's/^.*: "//' | sed 's/".*$//' |head -n 1)
#echo "IP_ADDRESS_PUBLIC=$IP_ADDRESS_PUBLIC">>NIGHTLY.ENV
