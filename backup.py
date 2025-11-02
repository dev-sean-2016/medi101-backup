"""
Kakao Cloud Object Storage 백업 프로그램
- 지정된 경로의 파일들을 Kakao Cloud Object Storage에 백업
- 로그 파일은 매일 덮어쓰기
- 타임스탬프 파일은 존재하지 않을 때만 업로드
- 파일 크기 비교하여 20MB 이상 차이나면 재업로드
- 버킷에 파일이 8개 이상이면 가장 오래된 파일 삭제
"""

import os
import sys
import json
import boto3
import logging
from datetime import datetime
from botocore.exceptions import ClientError, NoCredentialsError
from botocore.config import Config

# 로깅 설정
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
    """Kakao Cloud Object Storage 백업 클래스"""
    
    def __init__(self, config_path='config.json'):
        """
        초기화 함수
        Args:
            config_path: 설정 파일 경로
        """
        self.config = self._load_config(config_path)
        self.s3_client = self._create_s3_client()
        self.business_number = self.config['backup']['business_number']
        self.service_name = self.config['backup']['service_name']
        self.source_paths = self.config['backup']['source_paths']
        self.max_files_keep = self.config['backup']['max_files_keep']
        self.bucket_name = self.config['kakao_cloud']['bucket_name']
        
    def _load_config(self, config_path):
        """
        설정 파일 로드
        Args:
            config_path: 설정 파일 경로
        Returns:
            dict: 설정 정보
        """
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            logger.info(f"설정 파일 로드 완료: {config_path}")
            return config
        except FileNotFoundError:
            logger.error(f"설정 파일을 찾을 수 없습니다: {config_path}")
            logger.error("config.json.template 파일을 config.json으로 복사하고 값을 입력해주세요.")
            sys.exit(1)
        except json.JSONDecodeError as e:
            logger.error(f"설정 파일 JSON 파싱 오류: {e}")
            sys.exit(1)
            
    def _create_s3_client(self):
        """
        S3 호환 클라이언트 생성 (Kakao Cloud Object Storage)
        Returns:
            boto3.client: S3 클라이언트
        """
        try:
            kakao_config = self.config['kakao_cloud']
            
            # boto3 설정 (재시도 로직 포함)
            boto_config = Config(
                region_name=kakao_config['region'],
                retries={
                    'max_attempts': 5,
                    'mode': 'adaptive'
                },
                max_pool_connections=50
            )
            
            s3_client = boto3.client(
                's3',
                aws_access_key_id=kakao_config['access_key'],
                aws_secret_access_key=kakao_config['secret_key'],
                endpoint_url=kakao_config['endpoint_url'],
                config=boto_config
            )
            
            logger.info("Kakao Cloud Object Storage 클라이언트 생성 완료")
            return s3_client
            
        except KeyError as e:
            logger.error(f"설정 파일에 필수 항목이 없습니다: {e}")
            sys.exit(1)
        except Exception as e:
            logger.error(f"S3 클라이언트 생성 실패: {e}")
            sys.exit(1)
    
    def _get_file_size_mb(self, file_path):
        """
        파일 크기를 MB 단위로 반환
        Args:
            file_path: 파일 경로
        Returns:
            float: 파일 크기 (MB)
        """
        return os.path.getsize(file_path) / (1024 * 1024)
    
    def _get_s3_object_size_mb(self, s3_key):
        """
        S3 객체 크기를 MB 단위로 반환
        Args:
            s3_key: S3 객체 키
        Returns:
            float: 객체 크기 (MB), 존재하지 않으면 None
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
        멀티파트 업로드로 파일 업로드 (대용량 파일 처리)
        Args:
            file_path: 업로드할 파일 경로
            s3_key: S3 저장 키
        Returns:
            bool: 성공 여부
        """
        try:
            file_size_mb = self._get_file_size_mb(file_path)
            logger.info(f"업로드 시작: {file_path} ({file_size_mb:.2f} MB) -> {s3_key}")
            
            # boto3의 upload_file은 자동으로 멀티파트 업로드를 처리
            # 5GB 이상 파일은 자동으로 멀티파트로 업로드됨
            self.s3_client.upload_file(
                file_path,
                self.bucket_name,
                s3_key,
                Config=Config(
                    multipart_threshold=100 * 1024 * 1024,  # 100MB 이상이면 멀티파트
                    multipart_chunksize=100 * 1024 * 1024   # 청크 크기 100MB
                )
            )
            
            logger.info(f"업로드 완료: {s3_key}")
            return True
            
        except NoCredentialsError:
            logger.error("인증 오류: Access Key와 Secret Key를 확인해주세요.")
            return False
        except ClientError as e:
            logger.error(f"업로드 실패 ({s3_key}): {e}")
            return False
        except Exception as e:
            logger.error(f"예상치 못한 오류 ({s3_key}): {e}")
            return False
    
    def _should_upload_file(self, file_path, s3_key, file_name):
        """
        파일 업로드 여부 결정
        Args:
            file_path: 로컬 파일 경로
            s3_key: S3 객체 키
            file_name: 파일 이름
        Returns:
            tuple: (업로드 여부, 이유)
        """
        # 1. 로그 파일 (.log)은 항상 덮어쓰기
        if file_name == f"{self.service_name}.log":
            return True, "로그 파일 - 매일 덮어쓰기"
        
        # 2. 타임스탬프 파일 (서비스명_YYYYMMDDHHMMSS)
        if file_name.startswith(f"{self.service_name}_"):
            # S3에 동일한 파일명이 있는지 확인
            s3_size_mb = self._get_s3_object_size_mb(s3_key)
            
            # 파일이 존재하지 않으면 업로드하지 않음
            if s3_size_mb is None:
                return False, "S3에 파일이 없음 - 업로드 안 함"
            
            # 파일이 존재하면 크기 비교
            local_size_mb = self._get_file_size_mb(file_path)
            size_diff_mb = abs(local_size_mb - s3_size_mb)
            
            # 크기 차이가 20MB 이상이면 업로드
            if size_diff_mb >= 20:
                return True, f"파일 크기 차이 {size_diff_mb:.2f} MB - 재업로드"
            else:
                return False, f"파일 크기 유사 (차이 {size_diff_mb:.2f} MB) - 업로드 안 함"
        
        # 3. 기타 파일은 업로드하지 않음
        return False, "처리 대상이 아닌 파일"
    
    def backup_files(self):
        """
        소스 경로의 파일들을 백업
        """
        logger.info("=" * 80)
        logger.info(f"백업 시작: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        logger.info("=" * 80)
        
        upload_count = 0
        skip_count = 0
        error_count = 0
        
        for source_path in self.source_paths:
            if not os.path.exists(source_path):
                logger.warning(f"경로가 존재하지 않습니다: {source_path}")
                continue
            
            logger.info(f"소스 경로 스캔: {source_path}")
            
            # 경로 내의 모든 파일 처리
            for root, dirs, files in os.walk(source_path):
                for file_name in files:
                    file_path = os.path.join(root, file_name)
                    
                    # S3 저장 경로: {사업자번호}/{파일명}
                    s3_key = f"{self.business_number}/{file_name}"
                    
                    # 업로드 여부 확인
                    should_upload, reason = self._should_upload_file(
                        file_path, s3_key, file_name
                    )
                    
                    if should_upload:
                        logger.info(f"[업로드] {file_name} - {reason}")
                        if self._upload_file_with_multipart(file_path, s3_key):
                            upload_count += 1
                        else:
                            error_count += 1
                    else:
                        logger.info(f"[스킵] {file_name} - {reason}")
                        skip_count += 1
        
        # 오래된 파일 정리
        self._cleanup_old_files()
        
        # 결과 요약
        logger.info("=" * 80)
        logger.info("백업 완료")
        logger.info(f"업로드: {upload_count}개, 스킵: {skip_count}개, 오류: {error_count}개")
        logger.info("=" * 80)
    
    def _cleanup_old_files(self):
        """
        버킷의 사업자번호 경로에서 파일이 max_files_keep개 이상이면
        가장 오래된 파일 삭제
        """
        try:
            logger.info(f"파일 정리 시작: {self.business_number}/ 경로")
            
            # 사업자번호 경로의 모든 객체 조회
            prefix = f"{self.business_number}/"
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix
            )
            
            if 'Contents' not in response:
                logger.info("버킷에 파일이 없습니다.")
                return
            
            # 파일 목록 (타임스탬프 파일만)
            files = []
            for obj in response['Contents']:
                key = obj['Key']
                file_name = key.replace(prefix, '')
                
                # 타임스탬프 파일만 카운트 (로그 파일 제외)
                if file_name.startswith(f"{self.service_name}_"):
                    files.append({
                        'key': key,
                        'last_modified': obj['LastModified'],
                        'size': obj['Size'] / (1024 * 1024)  # MB
                    })
            
            logger.info(f"현재 백업 파일 개수: {len(files)}개 (최대: {self.max_files_keep}개)")
            
            # 최대 개수 초과시 오래된 파일 삭제
            if len(files) > self.max_files_keep:
                # 날짜순 정렬 (오래된 것부터)
                files.sort(key=lambda x: x['last_modified'])
                
                # 삭제할 파일 개수
                delete_count = len(files) - self.max_files_keep
                
                for i in range(delete_count):
                    file_to_delete = files[i]
                    logger.info(
                        f"오래된 파일 삭제: {file_to_delete['key']} "
                        f"({file_to_delete['last_modified']}, {file_to_delete['size']:.2f} MB)"
                    )
                    
                    self.s3_client.delete_object(
                        Bucket=self.bucket_name,
                        Key=file_to_delete['key']
                    )
                
                logger.info(f"{delete_count}개의 오래된 파일 삭제 완료")
            else:
                logger.info("파일 정리 불필요")
                
        except ClientError as e:
            logger.error(f"파일 정리 실패: {e}")
        except Exception as e:
            logger.error(f"예상치 못한 오류 (파일 정리): {e}")


def main():
    """메인 함수"""
    try:
        # 백업 실행
        backup = KakaoCloudBackup()
        backup.backup_files()
        
    except KeyboardInterrupt:
        logger.info("\n사용자에 의해 중단되었습니다.")
        sys.exit(0)
    except Exception as e:
        logger.error(f"치명적 오류: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()

