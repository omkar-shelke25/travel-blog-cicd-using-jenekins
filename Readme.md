Here's the updated README with the Jenkins CI pipeline code included:

---

# 🚀 Travel Blog CI/CD Pipeline

### 📌 **Project Overview**  
- Jenkins CI/CD pipeline for a travel blog website  
- Infrastructure provisioned using **Terraform**  
- Master-Slave Jenkins setup with Docker-based builds  

---

## 🏗️ **Infrastructure Setup**  
✅ **Provisioned using Terraform**  
✅ **Installed on Master and Slave:**  
- Docker  
- Java  
- Git  
- Trivy  

✅ **Installed on Master only:**  
- Jenkins  
- SonarQube (via Docker)  

✅ **Ports Exposed:**  
- Jenkins, Docker, SonarQube  

✅ **Manual Setup:**  
- Connected Jenkins Master to Slave  
- Added credentials for:  
  - Docker  
  - Git  
  - SonarQube  

---

## 🧪 **Continuous Integration (CI) Pipeline**  

### 📂 **Jenkinsfile (CI)**
```groovy
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
        
        stage("Docker Push Image") {
            steps {
                script {
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
```

---

## 🚀 **Continuous Deployment (CD) Pipeline**  
### 📂 **Jenkinsfile (CD)**
```groovy
pipeline {
    agent { label 'jenkins-agent' }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Frontend Docker tag to deploy')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Backend Docker tag to deploy')
    }

    stages {
        stage('Deploy Backend') {
            steps {
                script {
                    echo "Deploying backend..."
                    sh '''
                        docker stop travelblog-backend || true
                        docker rm travelblog-backend || true
                        docker pull omkar25/travelblog-backend-beta:${BACKEND_DOCKER_TAG}
                        docker run -d --name travelblog-backend -p 5000:5000 omkar25/travelblog-backend-beta:${BACKEND_DOCKER_TAG}
                    '''
                }
            }
        }

        stage('Deploy Frontend') {
            steps {
                script {
                    echo "Deploying frontend..."
                    sh '''
                        docker stop travelblog-frontend || true
                        docker rm travelblog-frontend || true
                        docker pull omkar25/travelblog-frontend-beta:${FRONTEND_DOCKER_TAG}
                        docker run -d --name travelblog-frontend -p 3000:3000 omkar25/travelblog-frontend-beta:${FRONTEND_DOCKER_TAG}
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo "Checking backend health..."
                    sh 'curl -f http://localhost:5000/health || exit 1'
                    echo "Checking frontend health..."
                    sh 'curl -f http://localhost:3000 || exit 1'
                }
            }
        }
    }

    post {
        success {
            echo 'Deployment successful'
        }
        failure {
            echo 'Deployment failed. Rolling back...'
            // Implement rollback strategy here if needed
        }
    }
}
```

---

## 🔁 **Post Actions**  
✅ **Always:**  
- Clean workspace  
- Prune Docker resources  

✅ **On Success:**  
- ✅ Pipeline completed successfully  

✅ **On Failure:**  
- ❌ Pipeline failed  

---

## 🏆 **How to Run**  
1. Clone the repository:  
```sh
git clone https://github.com/omkar-shelke25/travel-blog-cicd-using-jenekins.git
```

2. Configure Jenkins credentials:  
- Docker  
- Git  
- SonarQube  

3. Trigger the Jenkins **CI pipeline** with:  
- `FRONTEND_DOCKER_TAG`  
- `BACKEND_DOCKER_TAG`  

4. After successful CI, trigger the **CD pipeline** with the same tags.  

---

## 🚨 **Notes**  
- Ensure Jenkins master and slave are connected  
- Ensure Docker and SonarQube are running  
- Update environment scripts as needed  
- Set up proper rollback strategy in CD pipeline  

---

**🔹 DevOps FTW! 😎**