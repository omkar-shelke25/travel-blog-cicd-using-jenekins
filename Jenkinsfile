@Library("Sharable") _

pipeline {
    agent { label 'jenkins-agent' }

    environment {
        NVD_API_KEY = "${env.NVD_API_KEY}" // Fetch API key from Jenkins environment
    }

    stages {
        stage("Checkout The Code") {
            steps {
                script {
                    checkout_code("https://github.com/omkar-shelke25/travel-blog-cicd-using-jenekins", "main")
                }
            }
        }
        
        
        
        stage("Trivy vulnerability scan") {
            steps {
                script {
                    trivy_fs_scan()
                }
            }
        }
        
        stage("SonarQube: Code Analysis") {
            steps {
                script {
                    sonar("Sonar", "travel-blog", "travel-blog")
                }
            }
        }
        
        stage("SonarQube: Sonar Quality Gate") {
            steps {
                script {
                    sonar_QualityGate()
                }
            }
        }
       
       stage("Testing") {
            steps {
                script {
                    hello()
                }
            }
        }
        
    }
    
    post {
        always {
            script {
                node {
                    echo 'Cleaning up workspace...'
                    cleanWs()
                }
            }
        }
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
