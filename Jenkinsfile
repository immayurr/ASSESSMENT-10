pipeline {
    agent any
    
    parameters {
        string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'Tag for the Docker image')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Execute verification tests')
    }
    
    environment {
        DOCKER_HUB_USER = 'mayur123987'
        IMAGE_NAME = "smart-campus-energy"
        REGISTRY_CREDENTIALS_ID = 'dockerhub'
        KUBE_CREDENTIALS_ID = 'kuberconfig'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Parallel Build & Security Scan') {
            parallel {
                stage('Build Docker Image') {
                    steps {
                        script {
                            echo "Building Docker image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG}"
                            sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG} ."
                        }
                    }
                }
                stage('Lint HTML Components') {
                    steps {
                        echo "Scanning index.html structure..."
                        sh "grep -q 'Smart Campus Energy' index.html"
                    }
                }
            }
        }
        
        stage('Verify Application') {
            when {
                expression { return params.RUN_TESTS }
            }
            steps {
                echo "Running client rendering tests..."
                sh "grep -q 'Science Block' index.html"
                sh "grep -q 'Engineering Block' index.html"
                sh "grep -q 'Main Library' index.html"
            }
        }
        
        stage('Archive Build Artifacts') {
            steps {
                archiveArtifacts artifacts: 'index.html, Dockerfile, deployment.yaml', followSymlinks: false
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo '$PASS' | docker login -u '$USER' --password-stdin"
                        sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG}"
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes Cluster') {
            steps {
                script {
                    withKubeConfig([credentialsId: KUBE_CREDENTIALS_ID]) {
                        sh "sed -i 's|your-dockerhub-username/smart-campus-energy:latest|${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG}|g' deployment.yaml"
                        sh "kubectl apply -f deployment.yaml"
                        
                        echo "Verifying Rollout Status..."
                        timeout(time: 2, unit: 'MINUTES') {
                            try {
                                sh "kubectl rollout status deployment/energy-dashboard-deployment"
                            } catch (Exception e) {
                                echo "❌ Rollout failed! Initiating automated recovery rollback..."
                                sh "kubectl rollout undo deployment/energy-dashboard-deployment"
                                sh "kubectl rollout status deployment/energy-dashboard-deployment"
                                error("Deployment failed but system safely rolled back to stable release.")
                            }
                        }
                    }
                }
            }
        }
    }
}
