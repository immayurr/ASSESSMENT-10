pipeline {
    agent any
    
    parameters {
        string(name: 'DOCKER_TAG', defaultValue: 'v1.0.0', description: 'Target version tag for image publishing')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Toggle client execution tests')
    }
    
    environment {
        DOCKER_HUB_USER = 'mayur123987'
        IMAGE_NAME = "smart-campus-energy"
        REGISTRY_CREDENTIALS_ID = 'dockerhub'
        KUBE_CREDENTIALS_ID = 'kuberconfig'
    }
    
    stages {
        stage('Parallel Build & Validation') {
            parallel {
                stage('Build Engine') {
                    steps {
                        sh "docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG} ."
                    }
                }
                stage('Syntax Lint Verification') {
                    steps {
                        sh "grep -q 'Smart Campus Energy' index.html"
                    }
                }
            }
        }
        
        stage('Component Verification') {
            when {
                expression { return params.RUN_TESTS }
            }
            steps {
                sh "grep -q 'Science Block' index.html"
                sh "grep -q 'Engineering Block' index.html"
            }
        }
        
        stage('Archive Build Artifacts') {
            steps {
                archiveArtifacts artifacts: 'index.html, Dockerfile, deployment.yaml', followSymlinks: false
            }
        }
        
        stage('Push Image to Registry') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: REGISTRY_CREDENTIALS_ID, usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo '$PASS' | docker login -u '$USER' --password-stdin"
                        sh "docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG}"
                    }
                }
            }
        }
        
        stage('Kubernetes Orchestrated Rollout') {
            steps {
                script {
                    withKubeConfig([credentialsId: KUBE_CREDENTIALS_ID]) {
                        // Dynamically update image definitions inside manifest specs
                        sh "sed -i 's|your-dockerhub-username/smart-campus-energy:latest|${DOCKER_HUB_USER}/${IMAGE_NAME}:${params.DOCKER_TAG}|g' deployment.yaml"
                        sh "kubectl apply -f deployment.yaml"
                        
                        echo "Evaluating rollout progress status..."
                        timeout(time: 2, unit: 'MINUTES') {
                            try {
                                sh "kubectl rollout status deployment/energy-dashboard-deployment"
                            } catch (Exception e) {
                                echo "❌ Faulty release deployment encountered! Reverting infrastructure status..."
                                sh "kubectl rollout undo deployment/energy-dashboard-deployment"
                                sh "kubectl rollout status deployment/energy-dashboard-deployment"
                                error("Rollback executed: The previous stable running container configuration has been successfully restored.")
                            }
                        }
                    }
                }
            }
        }
    }
}
