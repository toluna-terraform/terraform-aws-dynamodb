#!/bin/bash
set -e
set -o pipefail

unset SERVICE_NAME
unset ACTION_TYPE
unset WORKSPACE
unset ENV_TYPE
unset AWS_PROFILE
unset INIT_DB_ENVIRONMENT
unset SOURCE_WORKSPACE
unset SOURCE_ENV_TYPE
unset SOURCE_AWS_PROFILE

usage() {
  cat <<EOM
    Usage:
    dynamo_actions.sh -s|--service_name <SERVICE_NAME> -a|--action <dynamo_backup/dynamo_restore> -w|--workspace <Terraform workspace> -e|--env_type <prod/non-prod> -p|--profile <AWS_PROFILE> -se|--src_env source environment to copy from -setype|--src_env_type the source environment type to copy from [prod|non-prod] -sp|src_profile source profile when running from local
    I.E. for backup 
    dynamo_actions.sh --service_name myService --action dynamo_backup --workspace my-data --env_type non-prod --profile my-aws-profile
    I.E. for restore
    dynamo_actions.sh --service_name myService --action dynamo_restore --workspace my-data --env_type non-prod --profile my-aws-profile
    I.E. for clone
    dynamo_actions.sh --service_name myService --action dynamo_restore --workspace my-data --env_type non-prod --profile my-aws-profile -se myCopyDb -sp my_source_profile --setype non-prod
EOM
    exit 1
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -s|--service_name)
      SERVICE_NAME="$2"
      DBNAME="$2"
      shift # past argument
      shift # past value
      ;;
    -a|--action)
      ACTION_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -w|--workspace)
      WORKSPACE="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--env_type)
      ENV_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--profile)
      AWS_PROFILE="$2"
      shift # past argument
      shift # past value
      ;;
    -se|--src_env)
      if [[ "$2" == "NULL" ]];
      then 
          unset INIT_DB_ENVIRONMENT
      else 
          INIT_DB_ENVIRONMENT="$2"
          SOURCE_WORKSPACE="$2"
      fi
      shift # past argument
      shift # past value
      ;;
    -setype|--src_env_type)
      SOURCE_ENV_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -sp|--src_profile)
      SOURCE_AWS_PROFILE="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
        usage
        shift # past argument
        shift # past value
      ;;
    *)    # unknown option
      echo "Error in command line parsing: unknown parameter ${*}" >&2
      exit 1
  esac
done

: ${SERVICE_NAME:?Missing -s|--service_name type -h for help}
: ${ACTION_TYPE:?Missing -a|--action type -h for help}
: ${WORKSPACE:?Missing -w|--workspace type -h for help}
: ${ENV_TYPE:?Missing -e|--env_type type -h for help}

if [[ ! -z "$INIT_DB_ENVIRONMENT" ]]; then
  : ${SOURCE_WORKSPACE:?Missing -se|--src_env type -h for help}
  : ${SOURCE_ENV_TYPE:?Missing -setype|--src_env_type type -h for help}
fi


### VALIDATE IF RUNNING LOCAL OR REMOTE ###
profile_status=$( (aws configure list --profile $AWS_PROFILE) 2>&1) || true
echo $profile_status
if [[ $profile_status = *'could not be found'* ]]; then
  unset LOCAL_RUN
  echo "Running on remote server"
else
  LOCAL_RUN=true
  echo "Running locally"
fi
### VALIDATE DUMP EXISTS FOR RESTORE ###
if [[ "${ACTION_TYPE}" == "dynamo_restore" ]]; then
  if [[ -z "$LOCAL_RUN" ]]; then
    object_not_exist=$( (aws s3api head-object --bucket "${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps" --key $WORKSPACE/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json) 2>&1) || true 
  else
    object_not_exist=$( (aws s3api head-object --bucket "${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps" --key $WORKSPACE/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json --profile $AWS_PROFILE) 2>&1) || true 
  fi
  if [[ $object_not_exist == *'Not Found'* && -z "${INIT_DB_ENVIRONMENT}" ]]; then
      echo "Dump file not found not performing restore:::${INIT_DB_ENVIRONMENT}"
      exit 0
  elif [[ -n "${INIT_DB_ENVIRONMENT}" ]]
  then
      ACTION_TYPE="dynamo_clone"
  else
      echo "Starting Restore..." 
  fi
fi

### dynamo DB BACKUP ###
dynamo_backup() {
  if [[ -z "$LOCAL_RUN" ]]; then
    aws s3api head-bucket --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps || bucket_not_exist=true
  else
    aws s3api head-bucket --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --profile $AWS_PROFILE || bucket_not_exist=true
  fi
  if [ $bucket_not_exist ]; then
    echo "Bucket not found, Creating new bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps..."
    if [[ -z "$LOCAL_RUN" ]]; then
      aws s3api create-bucket --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps
      aws s3api put-bucket-versioning --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --versioning-configuration Status=Enabled
      aws s3api put-public-access-block --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    else
      aws s3api create-bucket --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --profile $AWS_PROFILE --no-cli-pager
      aws s3api put-bucket-versioning --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --versioning-configuration Status=Enabled
      aws s3api put-public-access-block --bucket ${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" --profile $AWS_PROFILE
    fi
  fi
  if [[ -z "$LOCAL_RUN" ]]; then
    aws dynamodb scan --table-name dynamodb-${SERVICE_NAME}-${WORKSPACE} --region us-east-1 > /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
    aws s3 cp /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json s3://${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps/$WORKSPACE/
  else
    aws dynamodb scan --table-name dynamodb-${SERVICE_NAME}-${WORKSPACE} --profile $AWS_PROFILE --region us-east-1 > /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
    aws s3 cp /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json s3://${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps/$WORKSPACE/ --profile $AWS_PROFILE
  fi
  rm -f /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
}

dynamo_put_item(){
  local -a marks=( '/' '-' '\' '|' )
  for k in $(jq '.Items | keys | .[]' /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json); do
      printf 'Injecting Data, This may take a while please be patient...%s\r' "${marks[i++ % ${#marks[@]}]}"
      value=$(jq -r ".Items[$k]" /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json);
      echo $value > /tmp/item.json
      if [[ -z "$LOCAL_RUN" ]]; then
        aws dynamodb put-item --table-name dynamodb-${SERVICE_NAME}-${WORKSPACE} --item file:///tmp/item.json
      else
        aws dynamodb put-item --table-name dynamodb-${SERVICE_NAME}-${WORKSPACE} --profile $AWS_PROFILE --item file:///tmp/item.json
      fi
  done
  rm -f /tmp/item.json
  echo "Done importing Data."
}

dynamo_clone() {
  echo "Copying init db..."
  if [[ -z "$LOCAL_RUN" ]]; then
    aws dynamodb scan --table-name dynamodb-${SERVICE_NAME}-${SOURCE_WORKSPACE} --region us-east-1 > /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
  else
    aws dynamodb scan --table-name dynamodb-${SERVICE_NAME}-${SOURCE_WORKSPACE} --profile $SOURCE_AWS_PROFILE --region us-east-1 > /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
  fi
  dynamo_put_item
  rm -f /tmp/dynamodb-${SERVICE_NAME}-${SOURCE_WORKSPACE}.json
}

dynamo_restore() {
  if [[ -z "$LOCAL_RUN" ]]; then
    aws s3 cp s3://${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps/$WORKSPACE/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json /tmp/
   else
    aws s3 cp s3://${SERVICE_NAME}-${ENV_TYPE}-dynamodb-dumps/$WORKSPACE/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json /tmp/ --profile $AWS_PROFILE
  fi
  dynamo_put_item
  rm -f /tmp/dynamodb-${SERVICE_NAME}-${WORKSPACE}.json
}

$ACTION_TYPE
