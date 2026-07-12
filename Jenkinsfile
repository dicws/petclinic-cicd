pipeline {
    agent any
    environment {
        REGION      = "ca-central-1"
        ACCOUNT_ID  = "450444046629"
        ECR_NAME    = "user21-webserver"
        IMAGE_TAG   = "v3"
        ECR_REPO    = "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_NAME}"
        SONAR_PROJECT = "petclinic"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/dicws/petclinic-cicd.git'
            }
        }
        stage('Maven Build') {
            steps {
                sh '''
                chmod +x mvnw
                ./mvnw clean package -DskipTests
                '''
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                    ./mvnw sonar:sonar \
                      -Dsonar.projectKey=${SONAR_PROJECT} \
                      -Dsonar.projectName=${SONAR_PROJECT}
                    '''
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Trivy FileSystem Scan') {
            steps {
                sh '''
                trivy fs \
                  --scanners vuln,secret,misconfig \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress .
                '''
            }
        }
        stage('Docker Build') {
            steps {
                sh '''
                docker build -t ${ECR_NAME}:${IMAGE_TAG} .
                docker tag \
                ${ECR_NAME}:${IMAGE_TAG} \
                ${ECR_REPO}:${IMAGE_TAG}
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
                sh '''
                aws ecr get-login-password \
                  --region ${REGION} \
                | docker login \
                  --username AWS \
                  --password-stdin \
                  ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com
                docker push ${ECR_REPO}:${IMAGE_TAG}
                '''
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

