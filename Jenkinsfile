@Library("Sharable") _

pipeline {
    agent { label 'jenkins-agent' }
    
    environment {
        NVD_API_KEY = env.NVD_API_KEY // Fetch API key from Jenkins environment
    }
    
    stages {
        
        stage("Checkout Code") {
            steps {
                script {
                    echo "Checking out code from repository..."
                    checkout_code("https://github.com/omkar-shelke25/travel-blog-cicd-using-jenkins", "main")
                }
            }
        }
        
        stage("Security Scanning") {
            steps {
                script {
                    echo "Performing security scan using Trivy..."
                    trivy_fs_scan()
                }
            }
        }
        
        stage("Run Tests") {
            steps {
                script {
                    echo "Executing test cases..."
                    hello()
                }
            }
        }
       
        stage("Build Application") {
            steps {
                script {
                    echo "Checking for Dockerfile..."
                    if (!fileExists('Dockerfile')) {
                        error "Dockerfile not found!"
                    }
                    echo "Building Docker image..."
                    docker_build("note-app")
                }
            }
        }
        
    }
    
    post {
        always {
            echo "Cleaning up workspace..."
            cleanWs()
        }
        success {
            echo "Pipeline completed successfully."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
