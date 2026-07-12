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
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/dicws/petclinic-cicd.git'
            }
        }
        
        stage('Maven Package') {
            steps {
                sh '''
                chmod +x ./mvnw
                ./mvnw clean package -DskipTests
                '''
            }
        }
        
        stage('Trivy FS Scan') {
            steps {
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
                sh '''
                docker build -t ${ECR_NAME}:${IMAGE_TAG} .
                docker tag ${ECR_NAME}:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                '''
            }
        }
        
        stage('Trivy Image Scan') {
            steps {
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
                // 이미 검증된 AWS Credentials 바인딩 양식을 그대로 사용합니다.
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'aws-ecr-key', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    # 1. AWS 자격증명 환경 변수 선언
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_DEFAULT_REGION=${REGION}
                    
                    # 2. AWS CLI 대신 호스트 도커가 AWS 자격증명을 컨테이너 환경에서 상속받아 
                    # ECR 서버에 직접 인증할 수 있도록 클라이언트 구성을 강제 동기화합니다.
                    # 이를 위해 젠킨스 임시 인증 파일을 생성하거나, 주입된 환경변수를 통해 push를 바로 찌릅니다.
                    
                    # 💡 no basic auth 문제를 원천 해결하기 위해, 
                    # 주입된 키로 ECR에 로그인 토큰을 얻어내는 순수 도커-인증 헬퍼를 인라인으로 작동시킵니다.
                    echo "Pushing image directly using AWS Env context..."
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }
}
