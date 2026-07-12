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
                // withCredentials 대신 도커 전용 로그인 블록을 사용합니다.
                // registryUrl에는 본인의 ECR 주소(https:// 포함)를 적어줍니다.
                // credentialsId는 아까 사용한 'AWS Credentials' 타입의 'aws-ecr-key'를 그대로 씁니다.
                script {
                    docker.withRegistry("https://${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com", "aws-ecr-key") {
                        // 이 블록 안에서는 도커가 내부적으로 ECR 로그인 토큰을 자동으로 생성하여 로그인 상태를 유지합니다.
                        sh "docker push ${ECR_REPO}:${IMAGE_TAG}"
                    }
                }
            }
        }
    }
}
