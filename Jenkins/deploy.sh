#!/usr/bin/env bash

# set -e

##
# Read parameters from cfn.json
##
apt-get install jq
cat ./Jenkins/cfn.json

ROLE_ARN=$(jq -r ".targetAccountRoleArn" < ./Jenkins/cfn.json)
ARTIFACT_NAME=$(jq -r ".artifactsBucket" < ./Jenkins/cfn.json)
PREFIX=$(jq -r ".prefix" < ./Jenkins/cfn.json)
TARGET_ENVIRONMENT=$(jq -r ".environment" < ./Jenkins/cfn.json)
PROFILE=$(jq -r ".profile" < ./Jenkins/cfn.json)
ACCESS_KEY=$(jq -r ".access_key" < ./Jenkins/cfn.json)
SECRET_KEY=$(jq -r ".secret_key" < ./Jenkins/cfn.json)
SNSBUCKETNAME=$(jq -r ".s3SnsBucketName" < ./Jenkins/cfn.json)
KEYNAME=$(jq -r ".keyName" < ./Jenkins/cfn.json)



# do a aws ocnfigure in single line reading the secrets from the github secrets
aws configure set aws_access_key_id ${ACCESS_KEY}
aws configure set aws_secret_access_key ${SECRET_KEY}
aws configure set default.region eu-west-2

##
# Assuming the roles required to deploy on the target account.
##
ASSUMED_CREDENTIALS=$(aws sts get-session-token)
AWS_ACCESS_KEY_ID=$(echo "${ASSUMED_CREDENTIALS}" | jq -r .Credentials.AccessKeyId)
AWS_SECRET_ACCESS_KEY=$(echo "${ASSUMED_CREDENTIALS}" | jq -r .Credentials.SecretAccessKey)
AWS_SESSION_TOKEN=$(echo "${ASSUMED_CREDENTIALS}" | jq -r .Credentials.SessionToken)

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}"

##
# Package infrastructure
##
cd "${GITHUB_WORKSPACE}"/infrastructure

aws cloudformation package \
    --template-file vpcstack.yml \
    --s3-bucket "${ARTIFACT_NAME}" \
    --output-template-file vpcstack_release.yaml

aws cloudformation package \
    --template-file loadbalancer.yml \
    --s3-bucket "${ARTIFACT_NAME}" \
    --output-template-file loadbalancer_release.yaml

aws cloudformation package \
    --template-file apistack.yml \
    --s3-bucket "${ARTIFACT_NAME}" \
    --output-template-file apistack_release.yaml

aws cloudformation package \
--template-file masterstack.yml \
--s3-bucket "${ARTIFACT_NAME}" \
--output-template-file masterstack_release.yaml

cd "${GITHUB_WORKSPACE}"

aws s3 cp release/vpcstack_release.yaml s3://"${ARTIFACT_NAME}"/vpcstack_release.yaml
aws s3 cp release/loadbalancer_release.yaml s3://"${ARTIFACT_NAME}"/loadbalancer_release.yaml
aws s3 cp release/apistack_release.yaml s3://"${ARTIFACT_NAME}"/apistack_release.yaml

##
# Deploy infrastructure stack.
##
aws cloudformation deploy \
    --template-file "${GITHUB_WORKSPACE}"/infrastructure/aws-stacks/masterstack_release.yaml \
    --stack-name "${TARGET_ENVIRONMENT}"-"${PREFIX}"-master \
	--s3-bucket "${ARTIFACT_NAME}" \
	--capabilities CAPABILITY_AUTO_EXPAND CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
	--parameter-overrides \
    Prefix="${PREFIX}" \
    Environment="${TARGET_ENVIRONMENT}" \
    KeyName="${KEYNAME}"
    