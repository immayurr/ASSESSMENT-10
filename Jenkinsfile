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
                            bat "docker build -t %DOCKER_HUB_USER%/%IMAGE_NAME%:${params.DOCKER_TAG} ."
                        }
                    }
                }
                stage('Lint HTML Components') {
                    steps {
                        echo "Scanning index.html structure..."
                        bat "findstr /C:\"Smart Campus Energy\" index.html"
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
                bat "findstr /C:\"Science Block\" index.html"
                bat "findstr /C:\"Engineering Block\" index.html"
                bat "findstr /C:\"Main Library\" index.html"
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
                        bat "echo %PASS%| docker login -u %USER% --password-stdin"
                        bat "docker push %DOCKER_HUB_USER%/%IMAGE_NAME%:${params.DOCKER_TAG}"
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes Cluster') {
            steps {
                script {
                    withKubeConfig([credentialsId: KUBE_CREDENTIALS_ID]) {
                        // FAULTY FAULT INJECTION: Replaces the image with a broken/non-existent tag to force ImagePullBackOff
                        powershell "(Get-Content deployment.yaml) -replace 'your-dockerhub-username/smart-campus-energy:latest', '${DOCKER_HUB_USER}/${IMAGE_NAME}:invalid-tag-to-force-rollback' | Set-Content deployment.yaml"
                        bat "kubectl apply -f deployment.yaml"
                        
                        echo "Verifying Rollout Status..."
                        // Shortened timeout to 30 seconds for quick demonstration of the rollback
                        timeout(time: 30, unit: 'SECONDS') {
                            try {
                                bat "kubectl rollout status deployment/energy-dashboard-deployment"
                            } catch (Exception e) {
                                echo "❌ Rollout failed! Initiating automated recovery rollback..."
                                bat "kubectl rollout undo deployment/energy-dashboard-deployment"
                                bat "kubectl rollout status deployment/energy-dashboard-deployment"
                                error("Deployment failed but system safely rolled back to stable release.")
                            }
                        }
                    }
                }
            }
        }
    }
}
