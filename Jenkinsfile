pipeline {
    agent any
    
    environment {
        REGION = "ca-central-1"
        ECR_NAME = "user21-webserver"
        ACCOUNT_ID = "450444046629"
        IMAGE_TAG = "v2"
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_NAME}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                // 깃허브에서 소스코드 가져오기
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/dicws/petclinic-cicd.git'
            }
        }
        
        stage('Maven Package') {
            steps {
                // 자바 프로젝트 빌드
                sh '''
                chmod +x ./mvnw
                ./mvnw clean package -DskipTests
                '''
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
                // Dockerfile 및 소스코드 보안 검사 (취약점 발견 시 빌드 중단)
                sh '''
                trivy fs \
                  --scanners vuln,secret,misconfig \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress \
                  Dockerfile
                '''
            }
        }
        
        stage('Docker Build') {
            steps {
                // 도커 이미지 생성 및 태그 지정
                sh '''
                docker build -t ${ECR_NAME}:${IMAGE_TAG} .
                docker tag ${ECR_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
                // 생성된 도커 이미지 내부 취약점 검사 (취약점 발견 시 빌드 중단)
                sh '''
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress \
                  ${ECR_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('ECR Push') {
            steps {
                // 플러그인 특화 메서드 대신 젠킨스 기본 내장 기능을 사용합니다.
                withCredentials([usernamePassword(
                    credentialsId: 'aws-ecr-key', 
                    usernameVariable: 'AWS_ACCESS_KEY_ID', 
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                    # 1. 도커 내부의 AWS 인증 헬퍼용 환경 변수를 일시적으로 선언합니다.
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_DEFAULT_REGION=${REGION}
                    
                    # 2. AWS CLI(aws) 명령어 없이, 도커 표준 인증 바인딩 메커니즘을 이용해 푸시를 시도합니다.
                    # 젠킨스 도커 환경에 기본 내장된 amazon-ecr-credential-helper가 작동하거나, 
                    # 주입된 인증 정보를 기반으로 ECR 저장소 인증이 즉시 완료됩니다.
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }   
    }
}
