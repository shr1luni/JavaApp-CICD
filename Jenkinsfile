pipeline {
    agent any
    
    tools {
        maven 'Maven 3.9.12'
    }
    
    environment {
        DOCKER_HOST = 'unix:///var/run/docker.sock'
        DOCKER_TLS_VERIFY = ''
        DOCKER_CERT_PATH = ''
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'staging', url: 'https://github.com/shr1luni/JavaApp-CICD.git'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub-credentials', url: 'https://index.docker.io/v1/']) {
                        sh 'docker compose build'
                        sh 'docker compose push'
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                sh '''
                    echo "Deploying to Staging Environment..."
                    
                    docker stop staging-app staging-db 2>/dev/null || true
                    docker rm staging-app staging-db 2>/dev/null || true
                    docker network rm staging-net 2>/dev/null || true
                    
                    docker network create staging-net
                    
                    docker run -d --name staging-db --network staging-net \
                      -e MYSQL_ROOT_PASSWORD=root \
                      -e MYSQL_DATABASE=petclinic \
                      -v staging-mysql:/var/lib/mysql \
                      mysql:8
                    
                    sleep 30
                    
                    docker run -d --name staging-app --network staging-net \
                      -p 8080:8080 \
                      -e SPRING_DATASOURCE_URL=jdbc:mysql://staging-db:3306/petclinic \
                      -e SPRING_DATASOURCE_USERNAME=root \
                      -e SPRING_DATASOURCE_PASSWORD=root \
                      luniva6/spring-app:latest
                    
                    docker ps | grep staging
                    echo "Staging deployed at http://localhost:8080"
                '''
            }
        }
        
        stage('Approve Production Deployment') {
            steps {
                input message: 'Deploy to Production Environment?', ok: 'Deploy to Production'
            }
        }
        
        stage('Deploy to Production') {
            steps {
                sh '''
                    echo "Deploying to Production Environment..."
                    
                    docker stop prod-app prod-db 2>/dev/null || true
                    docker rm prod-app prod-db 2>/dev/null || true
                    docker network rm prod-net 2>/dev/null || true
                    
                    docker network create prod-net
                    
                    docker run -d --name prod-db --network prod-net \
                      -e MYSQL_ROOT_PASSWORD=root \
                      -e MYSQL_DATABASE=petclinic \
                      -v prod-mysql:/var/lib/mysql \
                      --restart=unless-stopped \
                      mysql:8
                    
                    sleep 30
                    
                    docker run -d --name prod-app --network prod-net \
                      -p 8081:8080 \
                      -e SPRING_DATASOURCE_URL=jdbc:mysql://prod-db:3306/petclinic \
                      -e SPRING_DATASOURCE_USERNAME=root \
                      -e SPRING_DATASOURCE_PASSWORD=root \
                      --restart=unless-stopped \
                      luniva6/spring-app:latest
                    
                    docker ps | grep prod
                    echo "Production deployed at http://localhost:8081"
                '''
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline executed successfully!'
            echo 'Staging: http://localhost:8080'
            echo 'Production: http://localhost:8081'
        }
        failure {
            echo 'Pipeline execution failed. Check logs above.'
        }
    }
}
EOF
