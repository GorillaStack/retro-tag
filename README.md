# Retro Tag

Retro Tag helps you retrospectively tag resources with the ARN of the user that created them. 

It is a spin off from Auto Tag, which tags resource as they are created.

This is designed to solve the problem of having untagged resources in your environment.

## About

Retro Tag uses the log data in your CloudTrail S3 bucket to gather information about who created your resource. Using this information, engineers can determine which resources are required, which are not and can cleanup the resources or improve their tagging. 

## Query CloudTrail logs using AWS Athena

Use AWS Athena to scan your history of CloudTrail logs in S3 and retro-actively tag existing AWS resources. You are charged based on the amount the data that is scanned.

Create Table Query
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS dev_cloudtrail (
eventversion STRING,
userIdentity STRUCT<
               type:STRING,
               principalid:STRING,
               arn:STRING,
               accountid:STRING,
               invokedby:STRING,
               accesskeyid:STRING,
               userName:STRING,
sessioncontext:STRUCT<
attributes:STRUCT<
               mfaauthenticated:STRING,
               creationdate:STRING>,
sessionIssuer:STRUCT<  
               type:STRING,
               principalId:STRING,
               arn:STRING, 
               accountId:STRING,
               userName:STRING>>>,
eventTime STRING,
eventSource STRING,
eventName STRING,
awsRegion STRING,
sourceIpAddress STRING,
userAgent STRING,
errorCode STRING,
errorMessage STRING,
requestParameters STRING,
responseElements STRING,
additionalEventData STRING,
requestId STRING,
eventId STRING,
resources ARRAY<STRUCT<
               ARN:STRING,
               accountId:STRING,
               type:STRING>>,
eventType STRING,
apiVersion STRING,
readOnly STRING,
recipientAccountId STRING,
serviceEventDetails STRING,
sharedEventID STRING,
vpcEndpointId STRING
)
ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://my-cloudtrail-bucket/dev/AWSLogs/11111111111/'
```

Data Query

```sql
SELECT eventTime, eventSource, eventName, awsRegion, userIdentity.accountId as "userIdentity.accountId", recipientAccountId, "$path" as key, requestParameters, responseElements
FROM dev_cloudtrail
WHERE
eventName in (
    'AllocateAddress',
    'CloneStack',
    'CopyImage',
    'CopySnapshot',
    'CreateAutoScalingGroup',
    'CreateBucket',
    'CreateDBInstance',
    'CreateImage',
    'CreateInternetGateway',
    'CreateLoadBalancer',
    'CreateNatGateway',
    'CreateNetworkAcl',
    'CreateNetworkInterface',
    'CreatePipeline',
    'CreateRouteTable',
    'CreateSecurityGroup',
    'CreateSnapshot',
    'CreateStack',
    'CreateSubnet',
    'CreateTable',
    'CreateVolume',
    'CreateVpc',
    'CreateVpnConnection',
    'CreateVpcPeeringConnection',
    'ImportImage',
    'ImportSnapshot',
    'RegisterImage',
    'RunInstances',
    'RunJobFlow'
)
and eventSource in (
    'autoscaling.amazonaws.com',
    'datapipeline.amazonaws.com',
    'dynamodb.amazonaws.com',
    'ec2.amazonaws.com',
    'elasticloadbalancing.amazonaws.com',
    'elasticmapreduce.amazonaws.com',
    'opsworks.amazonaws.com',
    'rds.amazonaws.com',
    's3.amazonaws.com'
)
and errorcode is null
```

## Tag Existing Resources

Use the `retro_tagging/retro_tag.rb` script to scan your environment for resources and then apply tagging to any resources that exist.

__TODO: add more information here__


## Contributing

If you have questions, feature requests or bugs to report, please do so on [the issues section of our github repository](https://github.com/GorillaStack/retro-tag/issues).

If you are interested in contributing, please get started by forking our GitHub repository and submit pull-requests.

