// ── PIPELINE BLOCK ────────────────────────────────────────────────────────────
// Everything lives inside here. This is a "declarative pipeline" — the modern
// structured way to write Jenkins pipelines.
pipeline {

    // ── AGENT ────────────────────────────────────────────────────────────────
    // "any" means: run this pipeline on any available Jenkins agent/node.
    // Since we only have one Jenkins server, it runs there.
    agent any

    // ── ENVIRONMENT VARIABLES ─────────────────────────────────────────────────
    // Variables available to every stage in the pipeline.
    // Change these values to match YOUR AWS account.
    environment {
        AWS_REGION        = "ap-south-1"
        AWS_ACCOUNT_ID    = "494003776090"          // ← your AWS account ID
        ECR_REPO_NAME     = "my-cicd-app"
        IMAGE_TAG         = "${BUILD_NUMBER}"        // Jenkins auto-increments this
        ECR_REGISTRY      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME   = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

        // The ID we set when adding AWS credentials to Jenkins in Step 7b
        AWS_CREDENTIALS_ID = "aws-credentials"

        // SSH credentials ID we will add next for deployment server access
        DEPLOY_SERVER_IP  = "43.204.140.75"    // ← your EC2 IP
    }

    // ── STAGES ───────────────────────────────────────────────────────────────
    // Stages run sequentially. If one fails, pipeline stops.
    stages {

        // ── STAGE 1: CHECKOUT ─────────────────────────────────────────────
        // Jenkins clones your GitHub repo into its workspace.
        // With a Multibranch or GitHub SCM job this happens automatically,
        // but we write it explicitly so the step is visible in the UI.
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ── STAGE 2: BUILD DOCKER IMAGE ────────────────────────────────────
        // Runs "docker build" using the Dockerfile in the repo root.
        // Tags the image with the ECR registry URL so it's ready to push.
        // BUILD_NUMBER is a Jenkins built-in — unique number per pipeline run.
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${FULL_IMAGE_NAME} .
                    """
                }
            }
        }

        // ── STAGE 3: PUSH TO ECR ───────────────────────────────────────────
        // Two things happen here:
        // 1. We authenticate Docker with ECR using AWS CLI
        //    "get-login-password" gives a temp token, we pipe it to docker login
        // 2. We push the image to ECR
        stage('Push to ECR') {
            steps {
                // withCredentials injects AWS keys as env vars temporarily.
                // They are masked in logs — you'll see **** instead of real values.
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        docker push ${FULL_IMAGE_NAME}
                    """
                }
            }
        }

        // ── STAGE 4: DEPLOY ────────────────────────────────────────────────
        // We SSH into the "deployment server" (same EC2, different directory)
        // and tell it to pull the new image and restart the app.
        // We pass the image name as an environment variable so docker compose
        // on the deployment side knows which image tag to pull.
        stage('Deploy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: "${AWS_CREDENTIALS_ID}"
                ]]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_SERVER_IP} '
                            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                            export AWS_REGION=${AWS_REGION}
                            export ECR_REGISTRY=${ECR_REGISTRY}
                            export IMAGE_TAG=${IMAGE_TAG}
                            export ECR_REPO_NAME=${ECR_REPO_NAME}

                            cd ~/deployment

                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}

                            docker compose pull
                            docker compose up -d
                        '
                    """
                }
            }
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    // Runs after all stages complete, regardless of success or failure.
    post {

        // Runs only if pipeline succeeded
        success {
            echo "Pipeline succeeded! Image ${FULL_IMAGE_NAME} is live."
        }

        // Runs only if pipeline failed
        failure {
            echo "Pipeline failed. Check the logs above."
        }

        // Always runs — good place to clean up dangling Docker images
        always {
            sh "docker image prune -f"
        }
    }
}
