pipeline {

    agent any

    environment {
        AWS_REGION         = "ap-south-1"
        AWS_ACCOUNT_ID     = "494003776090"
        ECR_REPO_NAME      = "my-cicd-app"
        IMAGE_TAG          = "${BUILD_NUMBER}"
        ECR_REGISTRY       = "494003776090.dkr.ecr.ap-south-1.amazonaws.com"
        FULL_IMAGE_NAME    = "494003776090.dkr.ecr.ap-south-1.amazonaws.com/my-cicd-app:${BUILD_NUMBER}"
        AWS_CREDENTIALS_ID = "aws-credentials"
        DEPLOY_SERVER_IP   = "3.110.141.223"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t 494003776090.dkr.ecr.ap-south-1.amazonaws.com/my-cicd-app:${BUILD_NUMBER} .
                    """
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws-credentials"
                ]]) {
                    sh """
                        aws ecr get-login-password --region ap-south-1 | \
                        docker login --username AWS --password-stdin 494003776090.dkr.ecr.ap-south-1.amazonaws.com

                        docker push 494003776090.dkr.ecr.ap-south-1.amazonaws.com/my-cicd-app:${BUILD_NUMBER}
                    """
                }
            }
        }


        stage('Deploy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "aws-credentials"
                ]]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                            -i /var/jenkins_home/.ssh/jenkins_deploy_key \
                            ubuntu@43.204.140.75 '

                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            export AWS_REGION=ap-south-1
                            export ECR_REGISTRY=494003776090.dkr.ecr.ap-south-1.amazonaws.com
                            export IMAGE_TAG=${BUILD_NUMBER}
                            export ECR_REPO_NAME=my-cicd-app

                            cd ~/deployment

                            aws ecr get-login-password --region ap-south-1 | \
                            docker login --username AWS --password-stdin 494003776090.dkr.ecr.ap-south-1.amazonaws.com

                            docker compose pull
                            docker compose up -d
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Image 494003776090.dkr.ecr.ap-south-1.amazonaws.com/my-cicd-app:${BUILD_NUMBER} is live."
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
        always {
            sh "docker image prune -f"
        }
    }
}
