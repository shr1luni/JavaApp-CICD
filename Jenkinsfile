pipeline {
    agent any
    
    tools {
        maven 'Maven 3.9.12'
    }
    
    environment {
        DOCKER_HOST = 'unix:///var/run/docker.sock'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'staging',
                    url: 'https://github.com/shr1luni/JavaApp-CICD.git'
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        
        stage('Fix Docker Permissions') {
            steps {
                sh 'sudo chmod 777 /var/run/docker.sock || true'
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub-credentials', url: 'https://index.docker.io/v1/']) {
                        sh '''
                            docker build -t luniva6/spring-app:latest .
                            docker tag luniva6/spring-app:latest luniva6/spring-app:build-${BUILD_NUMBER}
                            docker push luniva6/spring-app:latest
                            docker push luniva6/spring-app:build-${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                sh '''
                    echo "Stopping existing staging containers..."
                    docker stop staging-app staging-db 2>/dev/null || true
                    docker rm staging-app staging-db 2>/dev/null || true
                    docker network rm staging-net 2>/dev/null || true
                    
                    echo "Creating staging network..."
                    docker network create staging-net
                    
                    echo "Starting staging database..."
                    docker run -d --name staging-db --network staging-net \
                      -e MYSQL_ROOT_PASSWORD=root \
                      -e MYSQL_DATABASE=petclinic \
                      mysql:8
                    
                    sleep 30
                    
                    echo "Starting staging app..."
                    docker run -d --name staging-app --network staging-net \
                      -p 8080:8080 \
                      -e SPRING_DATASOURCE_URL=jdbc:mysql://staging-db:3306/petclinic \
                      -e SPRING_DATASOURCE_USERNAME=root \
                      -e SPRING_DATASOURCE_PASSWORD=root \
                      luniva6/spring-app:latest
                    
                    sleep 10
                    
                    echo "✅ Staging deployed at http://localhost:8080"
                    docker ps | grep staging-app
                '''
            }
        }
        
        stage('Approve Production') {
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
            }
        }
        
        stage('Deploy to Production') {
            steps {
                sh '''
                    echo "Stopping existing production containers..."
                    docker stop prod-app prod-db 2>/dev/null || true
                    docker rm prod-app prod-db 2>/dev/null || true
                    docker network rm prod-net 2>/dev/null || true
                    
                    echo "Creating production network..."
                    docker network create prod-net
                    
                    echo "Starting production database..."
                    docker run -d --name prod-db --network prod-net \
                      -e MYSQL_ROOT_PASSWORD=root \
                      -e MYSQL_DATABASE=petclinic \
                      -v prod-mysql:/var/lib/mysql \
                      --restart=unless-stopped \
                      mysql:8
                    
                    sleep 30
                    
                    echo "Starting production app..."
                    docker run -d --name prod-app --network prod-net \
                      -p 8081:8080 \
                      -e SPRING_DATASOURCE_URL=jdbc:mysql://prod-db:3306/petclinic \
                      -e SPRING_DATASOURCE_USERNAME=root \
                      -e SPRING_DATASOURCE_PASSWORD=root \
                      --restart=unless-stopped \
                      luniva6/spring-app:build-${BUILD_NUMBER}
                    
                    sleep 10
                    
                    echo "✅ Production deployed at http://localhost:8081"
                    docker ps | grep prod-app
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅✅✅ PIPELINE SUCCESSFUL! ✅✅✅'
            echo 'Staging: http://localhost:8080'
            echo 'Production: http://localhost:8081'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
