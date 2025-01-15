import json
import boto3
# Function to create the manifest file in the S3 bucket
def create_manifest():
    manifest = {
        "fileLocations": [
            {
                "URIPrefixes": [
                    "s3://vidhu-stock-data-bucket/stock_data/"
                ]
            }
        ],
        "globalUploadSettings": {
            "format": "JSON",
            "delimiter": ",",
            "containsHeader": "true"
        }
    }

    s3_client = boto3.client('s3')
    s3_client.put_object(
        Bucket='vidhu-stock-data-bucket',
        Key='manifest.json',
        Body=json.dumps(manifest),
        ContentType='application/json'
    )

# Run this function to create the manifest
create_manifest()