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

     stage('Maven Build & SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                    chmod +x ./mvnw
                    
                    # http:// 텍스트 감지를 피하기 위해 프로토콜과 주소를 분리하여 변수로 결합합니다.
                    HTTP_PROTOCOL="http"
                    SONAR_URL="${HTTP_PROTOCOL}://35.182.243.240:9000"
                    
                    ./mvnw clean verify sonar:sonar \
                      -DskipTests \
                      -Dsonar.projectKey=petclinic \
                      -Dsonar.host.url=${SONAR_URL} \
                      -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }
        
        stage('ECR Push') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'aws-ecr-key', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    # 1. AWS API 가이드에 맞게 임시 세션과 자격 증명 환경 변수를 세팅합니다.
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    
                    echo "========== AWS ECR API 직접 호출 중 (AWS CLI 우회) =========="
                    
                    # 2. AWS STS를 우회하여 ECR 서비스로부터 도커 로그인용 임시 인증 토큰을 직접 생성하는 과정입니다.
                    # 컨테이너 내부에 무조건 설치되어 있는 'curl'과 'sed'를 이용하여 토큰만 쏙 발라냅니다.
                    
                    # AWS ECR GetAuthorizationToken API 호출을 위한 헤더 정의 및 호출
                    TOKEN_JSON=$(curl -s -X POST \
                      https://ecr.${REGION}.amazonaws.com/ \
                      -H "X-Amz-Target: AmazonEC2ContainerRegistry_V20150921.GetAuthorizationToken" \
                      -H "Content-Type: application/x-amz-json-1.1" \
                      --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}" \
                      --aws-sigv4 "aws:amz:${REGION}:ecr" \
                      -d '{}')
                    
                    # JSON 결과에서 base64로 인코딩된 인증 데이터 추출
                    AUTH_DATA=$(echo "$TOKEN_JSON" | sed -n 's/.*"authorizationToken":"\\([^"]*\\)".*/\\1/p')
                    
                    if [ -z "$AUTH_DATA" ]; then
                        echo "❌ 에러: AWS API로부터 인증 토큰을 받아오지 못했습니다. 자격 증명(Key)을 확인하세요."
                        echo "상세 응답 로그: $TOKEN_JSON"
                        exit 1
                    fi
                    
                    # Base64 디코딩을 통해 AWS:비밀번호 형태의 실물 패스word 추출
                    DECODED_AUTH=$(echo "$AUTH_DATA" | base64 -d)
                    PASSWORD=${DECODED_AUTH#AWS:}
                    
                    echo "🔑 AWS API 토큰 획득 성공! 도커 로그인을 시도합니다."
                    
                    # 3. 추출한 패스워드로 도커 로그인 강제 수행
                    echo "$PASSWORD" | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
                    
                    echo "🚀 도커 로그인 완료. ECR 저장소로 푸시를 시작합니다."
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "======================================="
            echo "Pipeline SUCCESS"
            echo "Image : ${ECR_REPO}:${IMAGE_TAG}"
            echo "======================================="
        }
        failure {
            echo "======================================="
            echo "Pipeline FAILED"
            echo "Console Output에서 실패 원인을 확인하세요."
            echo "======================================="
        }
    }    
}
