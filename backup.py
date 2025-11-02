"""
Kakao Cloud Object Storage Backup Program (IAM Token Authentication)
- Backup files to Kakao Cloud Object Storage
- Log files: Daily overwrite
- Timestamp files: Upload only when they don't exist in S3
- Compare file size and re-upload if difference >= 20MB
- Delete oldest files if bucket has 8+ files
- Uses IAM token authentication (like sample.py)
"""

import os
import sys
import json
import boto3
import requests
import logging
import xml.etree.ElementTree as ET
from datetime import datetime
from botocore.exceptions import ClientError, NoCredentialsError
from botocore.config import Config
from boto3.s3.transfer import TransferConfig

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('backup.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class KakaoCloudBackup:
    """Kakao Cloud Object Storage Backup Class (IAM Token Authentication)"""
    
    def __init__(self, config_path='config.json'):
        """
        Initialize
        Args:
            config_path: Configuration file path
        """
        self.config = self._load_config(config_path)
        self.s3_client = self._create_s3_client_with_iam()
        self.business_number = self.config['backup']['business_number']
        self.service_name = self.config['backup']['service_name']
        self.source_paths = self.config['backup']['source_paths']
        self.max_files_keep = self.config['backup']['max_files_keep']
        self.bucket_name = self.config['kakao_cloud']['bucket_name']
        
    def _load_config(self, config_path):
        """
        Load configuration file
        Args:
            config_path: Configuration file path
        Returns:
            dict: Configuration
        """
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            logger.info(f"Configuration loaded: {config_path}")
            return config
        except FileNotFoundError:
            logger.error(f"Configuration file not found: {config_path}")
            logger.error("Please copy config.json.template to config.json and fill in the values.")
            sys.exit(1)
        except json.JSONDecodeError as e:
            logger.error(f"JSON parsing error: {e}")
            sys.exit(1)
    
    def _get_iam_token(self):
        """
        Get IAM authentication token (X-Subject-Token)
        Returns:
            str: X-Subject-Token
        """
        try:
            iam_config = self.config['kakao_cloud']['iam']
            url = "https://iam.kakaocloud.com/identity/v3/auth/tokens"
            
            headers = {
                "Content-Type": "application/json"
            }
            
            payload = {
                "auth": {
                    "identity": {
                        "methods": ["application_credential"],
                        "application_credential": {
                            "id": iam_config['application_credential_id'],
                            "secret": iam_config['application_credential_secret']
                        }
                    }
                }
            }
            
            logger.info("Requesting IAM token...")
            response = requests.post(url, headers=headers, json=payload)
            
            if response.status_code == 201:
                x_subject_token = response.headers.get('X-Subject-Token')
                if x_subject_token:
                    logger.info("IAM token acquired successfully")
                    return x_subject_token
                else:
                    logger.error("X-Subject-Token not found in response headers")
                    return None
            else:
                logger.error(f"IAM token request failed: {response.status_code}")
                logger.error(f"Response: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"IAM token request error: {e}")
            return None
    
    def _get_credentials(self, x_auth_token):
        """
        Get temporary credentials using X-Subject-Token
        Args:
            x_auth_token: X-Subject-Token
        Returns:
            str: XML response with credentials
        """
        try:
            endpoint = self.config['kakao_cloud']['endpoint_url']
            
            headers = {
                "Accept": "*/*",
                "Content-Type": "application/json"
            }
            
            payload = {
                "Action": "AssumeRoleWithWebIdentity",
                "DurationSeconds": 1800,
                "ProviderId": "iam.kakaocloud.com",
                "WebIdentityToken": x_auth_token
            }
            
            logger.info("Requesting temporary credentials...")
            response = requests.post(endpoint, headers=headers, json=payload)
            
            if response.status_code == 200:
                logger.info("Temporary credentials acquired successfully")
                return response.text
            else:
                logger.error(f"Credentials request failed: {response.status_code}")
                logger.error(f"Response: {response.text}")
                return None
                
        except Exception as e:
            logger.error(f"Credentials request error: {e}")
            return None
    
    def _parse_credentials_xml(self, xml_response):
        """
        Parse credentials from XML response
        Args:
            xml_response: XML response string
        Returns:
            dict: Parsed credentials
        """
        try:
            root = ET.fromstring(xml_response)
            
            # Find Credentials element
            credentials_elem = root.find('.//Credentials')
            if credentials_elem is not None:
                access_key = credentials_elem.find('AccessKeyId')
                secret_key = credentials_elem.find('SecretAccessKey')
                session_token = credentials_elem.find('SessionToken')
                expiration = credentials_elem.find('Expiration')
                
                if all([access_key is not None, secret_key is not None, session_token is not None]):
                    return {
                        'AccessKeyId': access_key.text,
                        'SecretAccessKey': secret_key.text,
                        'SessionToken': session_token.text,
                        'Expiration': expiration.text if expiration is not None else None
                    }
            
            # Try alternative structure
            access_key_text = None
            secret_key_text = None
            session_token_text = None
            
            for elem in root.iter():
                if 'AccessKeyId' in elem.tag:
                    access_key_text = elem.text
                elif 'SecretAccessKey' in elem.tag:
                    secret_key_text = elem.text
                elif 'SessionToken' in elem.tag:
                    session_token_text = elem.text
            
            if all([access_key_text, secret_key_text, session_token_text]):
                return {
                    'AccessKeyId': access_key_text,
                    'SecretAccessKey': secret_key_text,
                    'SessionToken': session_token_text
                }
            
            return None
            
        except Exception as e:
            logger.error(f"XML parsing error: {e}")
            return None
    
    def _create_s3_client_with_iam(self):
        """
        Create S3 client (supports both IAM token and static access key)
        Returns:
            boto3.client: S3 client
        """
        try:
            kakao_config = self.config['kakao_cloud']
            
            boto_config = Config(
                region_name=kakao_config['region'],
                retries={
                    'max_attempts': 5,
                    'mode': 'adaptive'
                },
                max_pool_connections=50
            )
            
            # Check which authentication method to use
            if 'iam' in kakao_config:
                # Method 1: IAM token authentication (recommended)
                logger.info("Using IAM token authentication")
                
                # Step 1: Get IAM token
                x_subject_token = self._get_iam_token()
                if not x_subject_token:
                    logger.error("Failed to get IAM token")
                    sys.exit(1)
                
                # Step 2: Get temporary credentials
                credentials_xml = self._get_credentials(x_subject_token)
                if not credentials_xml:
                    logger.error("Failed to get temporary credentials")
                    sys.exit(1)
                
                # Step 3: Parse credentials
                credentials = self._parse_credentials_xml(credentials_xml)
                if not credentials:
                    logger.error("Failed to parse credentials")
                    sys.exit(1)
                
                # Step 4: Create S3 client with temporary credentials
                s3_client = boto3.client(
                    's3',
                    aws_access_key_id=credentials['AccessKeyId'],
                    aws_secret_access_key=credentials['SecretAccessKey'],
                    aws_session_token=credentials['SessionToken'],
                    endpoint_url=kakao_config['endpoint_url'],
                    config=boto_config
                )
                
                logger.info("S3 client created (IAM authentication)")
                
            elif 'access_key' in kakao_config and 'secret_key' in kakao_config:
                # Method 2: Static access key authentication (legacy)
                logger.info("Using static access key authentication")
                
                s3_client = boto3.client(
                    's3',
                    aws_access_key_id=kakao_config['access_key'],
                    aws_secret_access_key=kakao_config['secret_key'],
                    endpoint_url=kakao_config['endpoint_url'],
                    config=boto_config
                )
                
                logger.info("S3 client created (static key authentication)")
                
            else:
                logger.error("Invalid configuration: Must have either 'iam' or 'access_key'+'secret_key'")
                logger.error("Config has: " + ", ".join(kakao_config.keys()))
                sys.exit(1)
            
            return s3_client
            
        except KeyError as e:
            logger.error(f"Missing configuration: {e}")
            sys.exit(1)
        except Exception as e:
            logger.error(f"Failed to create S3 client: {e}")
            sys.exit(1)
    
    def _get_file_size_mb(self, file_path):
        """
        Get file size in MB
        Args:
            file_path: File path
        Returns:
            float: File size (MB)
        """
        return os.path.getsize(file_path) / (1024 * 1024)
    
    def _get_s3_object_size_mb(self, s3_key):
        """
        Get S3 object size in MB
        Args:
            s3_key: S3 object key
        Returns:
            float: Object size (MB), None if not exists
        """
        try:
            response = self.s3_client.head_object(
                Bucket=self.bucket_name,
                Key=s3_key
            )
            return response['ContentLength'] / (1024 * 1024)
        except ClientError:
            return None
    
    def _upload_file_with_multipart(self, file_path, s3_key):
        """
        Upload file with multipart upload (for large files)
        Args:
            file_path: File path to upload
            s3_key: S3 key
        Returns:
            bool: Success
        """
        try:
            file_size_mb = self._get_file_size_mb(file_path)
            logger.info(f"Upload start: {file_path} ({file_size_mb:.2f} MB) -> {s3_key}")
            
            # TransferConfig for multipart upload
            transfer_config = TransferConfig(
                multipart_threshold=100 * 1024 * 1024,  # 100MB+
                multipart_chunksize=100 * 1024 * 1024,   # 100MB chunks
                max_concurrency=10,
                use_threads=True
            )
            
            # boto3 automatically handles multipart upload
            self.s3_client.upload_file(
                file_path,
                self.bucket_name,
                s3_key,
                Config=transfer_config
            )
            
            logger.info(f"Upload complete: {s3_key}")
            return True
            
        except NoCredentialsError:
            logger.error("Authentication error: Check Access Key and Secret Key")
            return False
        except ClientError as e:
            logger.error(f"Upload failed ({s3_key}): {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error ({s3_key}): {e}")
            return False
    
    def _should_upload_file(self, file_path, s3_key, file_name):
        """
        Determine whether to upload a file
        Args:
            file_path: Local file path
            s3_key: S3 object key
            file_name: File name
        Returns:
            tuple: (should_upload, reason)
        """
        # 1. Log files (.log) always overwrite
        if file_name == f"{self.service_name}.log":
            return True, "LOG_FILE_DAILY_OVERWRITE"
        
        # 2. Timestamp files (ServiceName_YYYYMMDDHHMMSS)
        if file_name.startswith(f"{self.service_name}_"):
            # Check if file exists in S3
            s3_size_mb = self._get_s3_object_size_mb(s3_key)
            
            # If file does NOT exist in S3, UPLOAD it
            if s3_size_mb is None:
                return True, "NOT_EXISTS_IN_S3_UPLOAD"
            
            # If file exists, compare size
            local_size_mb = self._get_file_size_mb(file_path)
            size_diff_mb = abs(local_size_mb - s3_size_mb)
            
            # If size difference >= 20MB, re-upload
            if size_diff_mb >= 20:
                return True, f"SIZE_DIFF_{size_diff_mb:.2f}MB_REUPLOAD"
            else:
                return False, f"SIZE_SIMILAR_DIFF_{size_diff_mb:.2f}MB_SKIP"
        
        # 3. Other files are not uploaded
        return False, "NOT_TARGET_FILE"
    
    def backup_files(self):
        """
        Backup files from source paths
        """
        logger.info("=" * 80)
        logger.info(f"Backup start: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 80)
        
        upload_count = 0
        skip_count = 0
        error_count = 0
        
        for source_path in self.source_paths:
            if not os.path.exists(source_path):
                logger.warning(f"Path not found: {source_path}")
                continue
            
            logger.info(f"Scanning source path: {source_path}")
            
            # Process all files in path
            for root, dirs, files in os.walk(source_path):
                for file_name in files:
                    file_path = os.path.join(root, file_name)
                    
                    # S3 storage path: {business_number}/{filename}
                    s3_key = f"{self.business_number}/{file_name}"
                    
                    # Check if should upload
                    should_upload, reason = self._should_upload_file(
                        file_path, s3_key, file_name
                    )
                    
                    if should_upload:
                        logger.info(f"[UPLOAD] {file_name} - {reason}")
                        if self._upload_file_with_multipart(file_path, s3_key):
                            upload_count += 1
                        else:
                            error_count += 1
                    else:
                        logger.info(f"[SKIP] {file_name} - {reason}")
                        skip_count += 1
        
        # Cleanup old files
        self._cleanup_old_files()
        
        # Summary
        logger.info("=" * 80)
        logger.info("Backup complete")
        logger.info(f"Uploaded: {upload_count}, Skipped: {skip_count}, Errors: {error_count}")
        logger.info("=" * 80)
    
    def _cleanup_old_files(self):
        """
        Delete oldest files if bucket has max_files_keep+ files
        """
        try:
            logger.info(f"Cleanup start: {self.business_number}/ path")
            
            # List all objects in business_number path
            prefix = f"{self.business_number}/"
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix
            )
            
            if 'Contents' not in response:
                logger.info("No files in bucket")
                return
            
            # File list (timestamp files only)
            files = []
            for obj in response['Contents']:
                key = obj['Key']
                file_name = key.replace(prefix, '')
                
                # Count only timestamp files (exclude log files)
                if file_name.startswith(f"{self.service_name}_"):
                    files.append({
                        'key': key,
                        'last_modified': obj['LastModified'],
                        'size': obj['Size'] / (1024 * 1024)  # MB
                    })
            
            logger.info(f"Current backup files: {len(files)} (max: {self.max_files_keep})")
            
            # Delete old files if exceeds max
            if len(files) > self.max_files_keep:
                # Sort by date (oldest first)
                files.sort(key=lambda x: x['last_modified'])
                
                # Number of files to delete
                delete_count = len(files) - self.max_files_keep
                
                for i in range(delete_count):
                    file_to_delete = files[i]
                    logger.info(
                        f"Deleting old file: {file_to_delete['key']} "
                        f"({file_to_delete['last_modified']}, {file_to_delete['size']:.2f} MB)"
                    )
                    
                    self.s3_client.delete_object(
                        Bucket=self.bucket_name,
                        Key=file_to_delete['key']
                    )
                
                logger.info(f"Deleted {delete_count} old files")
            else:
                logger.info("No cleanup needed")
                
        except ClientError as e:
            logger.error(f"Cleanup failed: {e}")
        except Exception as e:
            logger.error(f"Unexpected error (cleanup): {e}")


def main():
    """Main function"""
    try:
        # Run backup
        backup = KakaoCloudBackup()
        backup.backup_files()
        
    except KeyboardInterrupt:
        logger.info("\nInterrupted by user")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
