pipeline {
agent any
environment {
AWS_REGION = 'ap-south-2'
ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text',
returnStdout: true).trim()
ECR_REGISTRY = "${ACCOUNT_ID}.dkr.ecr.ap-south-2.amazonaws.com"
ECR_REPO = 'cicd-demo-app'
IMAGE_TAG = "build-${BUILD_NUMBER}-${GIT_COMMIT[0..6]}"
FULL_IMAGE = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
TF_DIR = 'terraform'
CLUSTER = 'cicd-demo-app-cluster'
SERVICE = 'cicd-demo-app-service'
}
options {
buildDiscarder(logRotator(numToKeepStr: '10'))
timeout(time: 30, unit: 'MINUTES')
timestamps()
}
stages {
stage('Checkout') {
steps {
echo '====> Stage 1: Checking out source code'
checkout scm
sh 'git log --oneline -3'
}
}
stage('Test') {
steps {
echo '====> Stage 2: Running tests'
sh 'npm install'
sh 'npm test'
}
}
stage('Build Docker Image') {
steps {
echo "====> Stage 3: Building ${env.FULL_IMAGE}"
sh """
docker build \\
--build-arg APP_VERSION=${IMAGE_TAG} \\
--label build.number=${BUILD_NUMBER} \\
-t ${FULL_IMAGE} \\
-t ${ECR_REGISTRY}/${ECR_REPO}:latest \\
."""
}
}
stage('Push to ECR') {
steps {
echo '====> Stage 4: Pushing image to ECR (using IAM Role)'
sh """
aws ecr get-login-password --region ${AWS_REGION} \\
| docker login --username AWS --password-stdin ${ECR_REGISTRY}
docker push ${FULL_IMAGE}
docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
"""
}
}
stage('Terraform Init') {
steps {
echo '====> Stage 5: Initializing Terraform'
dir(env.TF_DIR) {
sh 'terraform init -input=false'
sh 'terraform validate'
}
}
}
stage('Terraform Plan') {
steps {
echo '====> Stage 6: Planning Terraform changes'
dir(env.TF_DIR) {
sh "terraform plan -var=\"ecr_image_uri=${FULL_IMAGE}\" -input=false -out=tfplan"
sh 'terraform show -no-color tfplan'
}
}
}
stage('Terraform Apply') {
steps {
echo '====> Stage 7: Applying Terraform (infrastructure provisioning)'
dir(env.TF_DIR) {
sh 'terraform apply -input=false -auto-approve tfplan'
script {
env.ALB_DNS = sh(
script: 'terraform output -raw alb_dns_name',
returnStdout: true).trim()
}
}
}
}
stage('Deploy to ECS') {
steps {
echo '====> Stage 8: Triggering ECS rolling deployment'
sh """
aws ecs update-service \\
--cluster ${CLUSTER} --service ${SERVICE} \\
--force-new-deployment --region ${AWS_REGION}
echo 'Waiting for deployment to stabilize...'
aws ecs wait services-stable \\
--cluster ${CLUSTER} --services ${SERVICE} \\
--region ${AWS_REGION}
"""
}
}
stage('Smoke Test') {
steps {
echo '====> Stage 9: Running smoke test'
sh """
sleep 30
STATUS=\$(curl -o /dev/null -s -w \"%{http_code}\"
http://${env.ALB_DNS}/health)
if [ \"\$STATUS\" != \"200\" ]; then exit 1; fi
echo \"PASSED: http://${env.ALB_DNS} is live!\"
"""
}
}
}
post {
success { echo "App deployed: http://${env.ALB_DNS}" }
failure { echo 'Pipeline FAILED — check console output above' }
always {
sh "docker rmi ${FULL_IMAGE} || true"
sh "docker rmi ${ECR_REGISTRY}/${ECR_REPO}:latest || true"
sh 'docker system prune -f || true'
}
}
}
