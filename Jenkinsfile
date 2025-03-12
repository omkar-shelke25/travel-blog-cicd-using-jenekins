@Library("Sharable") _

pipeline {
    agent { label 'jenkins-agent' }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }

    environment {
        NVD_API_KEY = "${env.NVD_API_KEY}" // Fetch API key from Jenkins environment
        DOCKER_STATUS = "systemctl is-active docker || echo 'inactive'"
    }

    stages {
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                    }
                }
            }
        }
        
        stage("Cleanup Workspace") {
            steps {
                script {
                    echo 'Cleaning up workspace before checkout...'
                    cleanWs()
                }
            }
        }

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
        
        stage('Exporting environment variables') {
            parallel {
                stage("Backend env setup") {
                    steps {
                        script {
                            dir("update_env") {
                                sh "bash updatebackendnew.sh"
                            }
                        }
                    }
                }
                
                stage("Frontend env setup") {
                    steps {
                        script {
                            dir("update_env") {
                                sh "bash updatefrontendnew.sh"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Check Docker Status') {
            steps {
                script {
                    def status = sh(script: "${DOCKER_STATUS}", returnStdout: true).trim()
                    if (status != 'active') {
                        echo "Docker is not running. Starting Docker..."
                        sh 'sudo systemctl start docker'
                        sleep(5) // Give Docker some time to start
                        status = sh(script: "${DOCKER_STATUS}", returnStdout: true).trim()
                        if (status != 'active') {
                            error("Failed to start Docker!")
                        }
                    } else {
                        echo "Docker is running."
                    }
                }
            }
        }

        stage("Docker: Build Images") {
            steps {
                script {
                    dir('backend') {
                        docker_build("travelblog-backend-beta", "${params.BACKEND_DOCKER_TAG}")
                    }
                    dir('frontend') {
                        docker_build("travelblog-frontend-beta", "${params.FRONTEND_DOCKER_TAG}")
                    }
                }
            }
        }
        
        stage("Docker Push Image")
        {
            steps{
                script{
                    docker_push("travelblog-backend-beta", "${params.BACKEND_DOCKER_TAG}")
                    docker_push("travelblog-frontend-beta", "${params.FRONTEND_DOCKER_TAG}")
                    
                }
            }
        }
    }

    post {
        always {
            script {
                echo 'Cleaning up workspace...'
                cleanWs()
                
                echo 'Pruning Docker resources...'
                sh 'docker system prune --all --force --volumes'
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
