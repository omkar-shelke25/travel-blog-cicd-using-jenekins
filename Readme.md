# 🚀 Travel Blog CI/CD Pipeline

## 📌 **Project Overview**  
This project sets up a **CI/CD pipeline** for a travel blog website using **Jenkins**. The pipeline is designed to automate the building, testing, and deployment processes, ensuring that code changes are integrated and deployed efficiently and reliably. The infrastructure is provisioned using **Terraform**, setting up a **Jenkins Master-Slave** architecture to handle the build and deployment tasks. 

The CI pipeline covers steps such as code checkout, vulnerability scanning, code analysis, and Docker image creation and pushing. The CD pipeline handles the deployment of the Docker containers and performs health checks to validate the deployment.

---

## 🏗️ **Infrastructure Setup**  
The infrastructure is provisioned using **Terraform**, which automates the creation of both the Jenkins master and slave instances. This ensures that the environment is consistent and repeatable.

### 🔧 **Installed Tools and Services**  
After provisioning the infrastructure, the following tools are installed on the instances:

- **Docker** – Installed on both the master and the slave instances to build and run containerized applications.  
- **Java** – Required to run Jenkins and some Java-based applications.  
- **Git** – To clone and manage the code repository.  
- **Trivy** – Installed for vulnerability scanning to ensure secure builds.  
- **Jenkins** – Installed only on the master node to manage the CI/CD pipeline.  
- **SonarQube** – Installed on the master node using Docker, for static code analysis and quality checks.  

### 🌐 **Ports and Network Configuration**  
The necessary ports for Jenkins, Docker, and SonarQube are exposed to allow communication between the Jenkins master and the Jenkins slave, and to enable access to the services from the browser.

### 🔗 **Jenkins Master-Slave Connection**  
Once the Jenkins master and slave instances are up and running, the connection between them is established manually. This allows the master to distribute jobs to the slave nodes for parallel execution, improving build efficiency.

---

## 🧪 **Continuous Integration (CI) Pipeline**  
The CI pipeline is defined in a `Jenkinsfile` and handles the process of building, testing, and analyzing the code. The pipeline includes the following stages:

### 1. 🏷️ **Validate Parameters**  
This stage ensures that the Docker tags for both the frontend and backend are provided before proceeding with the pipeline. If any of the required tags are missing, the pipeline will fail immediately.

### 2. 🧹 **Cleanup Workspace**  
To avoid conflicts with previous builds, the workspace is cleaned at the beginning of the pipeline. This removes any leftover files or artifacts from the last build.

### 3. 🛒 **Checkout The Code**  
The pipeline pulls the latest code from the GitHub repository using Jenkins credentials. This ensures that the most recent changes are included in the build process.

### 4. 🔎 **Trivy Vulnerability Scan**  
Trivy scans the project files for vulnerabilities and reports any issues found. If critical vulnerabilities are detected, the pipeline can be configured to fail automatically.

### 5. 🧪 **SonarQube Code Analysis**  
SonarQube performs static code analysis to identify code quality issues such as bugs, security vulnerabilities, and code smells. The results are available in the SonarQube dashboard.

### 6. 🚦 **SonarQube Quality Gate**  
After the code analysis, the pipeline checks the SonarQube quality gate. If the quality gate fails due to high levels of complexity, poor test coverage, or security issues, the pipeline will stop.

### 7. 🧪 **Testing**  
Automated tests are executed to verify the functionality and performance of the application. This helps identify any regressions introduced by recent changes.

### 8. 🌍 **Exporting Environment Variables**  
Environment variables for both the backend and frontend are set up using shell scripts. This step configures the application runtime environment.

### 9. 🐋 **Check Docker Status**  
The pipeline verifies that Docker is running on the slave instance. If Docker is not running, it will attempt to start it automatically.

### 10. 🏗️ **Docker Build Images**  
Separate Docker images are built for the frontend and backend. The Docker tags provided as parameters are used to label the images.

### 11. 📤 **Docker Push Images**  
The built Docker images are pushed to a container registry (like Docker Hub) for deployment.

---

### 📂 **Jenkinsfile (CI)**
The full Jenkins CI pipeline code is shown below:

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

```

---

## 🚀 **Continuous Deployment (CD) Pipeline**  
The CD pipeline deploys the Docker images created during the CI pipeline to a running environment. The pipeline performs the following tasks:

1. **Stop Existing Containers:**  
   Any running backend or frontend containers are stopped and removed.

2. **Pull Latest Docker Images:**  
   The latest backend and frontend images are pulled from the container registry.

3. **Start New Containers:**  
   New containers are started using the latest Docker images.

4. **Health Check:**  
   The pipeline checks the health of the backend and frontend services by sending HTTP requests. If the health check fails, the pipeline can roll back to the previous version.

5. **Rollback (Optional):**  
   If the deployment fails, the pipeline can be configured to automatically roll back to the last working version.

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
                    sh '''
                        docker stop travelblog-backend || true
                        docker rm travelblog-backend || true
                        docker pull omkar25/travelblog-backend-beta:${BACKEND_DOCKER_TAG}
                        docker run -d --name travelblog-backend -p 5000:5000 omkar25/travelblog-backend-beta:${BACKEND_DOCKER_TAG}
                    '''
                }
            }
        }
        // Other stages as explained above...
    }
}
```

---

## ✅ **Post Actions**  
- **Success:** Clean up Docker resources and mark the pipeline as successful.  
- **Failure:** Clean up the workspace and notify of the failure.  

---

## 🏆 **How to Run**  
1. Clone the repository:  
```sh
git clone https://github.com/omkar-shelke25/travel-blog-cicd-using-jenekins.git
```
2. Configure Jenkins credentials for Git, Docker, and SonarQube.  
3. Trigger the CI pipeline.  
4. After a successful CI run, trigger the CD pipeline.  

---

## 🚨 **Notes**  
- Ensure Jenkins master and slave nodes are connected.  
- Docker and SonarQube must be running.  
- Configure rollback strategy in the CD pipeline.  

---

**🔹 DevOps FTW! 😎**