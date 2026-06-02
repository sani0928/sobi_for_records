pipeline {
    agent any

    environment {
        COMPOSE_FILE = 'docker-compose.web.yaml'
        PROJECT_NAME = 'sobi-web'
        PROJECT_DIR = '.'
        NGINX_CONTAINER = 'sobi-nginx'
        NGINX_CONF_DIR = '/var/jenkins_home/nginx'
    }

    stages {
        stage('Decide Target Color') {
            steps {
                script {
                    def active = sh(script: "grep -q 'sobi-backend-blue' ${NGINX_CONF_DIR}/nginx.conf && echo blue || echo green", returnStdout: true).trim()
                    if (active == "blue") {
                        env.CURRENT_COLOR = "blue"
                        env.DEPLOY_COLOR = "green"
                    } else {
                        env.CURRENT_COLOR = "green"
                        env.DEPLOY_COLOR = "blue"
                    }
                    echo "Current active: ${env.CURRENT_COLOR}, deploying new version to: ${env.DEPLOY_COLOR}"
                }
            }
        }

        stage('Prepare Env File') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'sobi-db-user', variable: 'DATABASE_USERNAME'),
                        string(credentialsId: 'sobi-db-pass', variable: 'DATABASE_PASSWORD'),
                        string(credentialsId: 'sobi-jwt-secret', variable: 'JWT_SECRET')
                    ]) {
                        sh '''
                            echo "NODE_ENV=production" > .env
                            echo "PORT=3000" >> .env
                            echo "NEXT_PUBLIC_API_BASE_URL=https://13.125.215.242" >> .env
                            echo "NEXT_PUBLIC_FRONTEND_URL=https://13.125.215.242" >> .env

                            echo "DATABASE_URL=jdbc:postgresql://sobi-db:5432/sobi" >> .env
                            echo "DATABASE_USERNAME=$DATABASE_USERNAME" >> .env
                            echo "DATABASE_PASSWORD=$DATABASE_PASSWORD" >> .env

                            echo "JPA_SHOW_SQL=true" >> .env
                            echo "JPA_DDL_AUTO=update" >> .env
                            echo "JPA_OPEN_IN_VIEW=false" >> .env

                            echo "JWT_SECRET=$JWT_SECRET" >> .env
                            echo "MQTT_BROKER_URL=tcp://mqtt:1883" >> .env
                            echo "BASKET_CACHE_TTL_SECONDS=7200" >> .env
                            echo "REDIS_HOST=redis" >> .env
                            echo "REDIS_PORT=6379" >> .env
                            echo "AI_RECOMMENDATION_URL=http://172.26.6.236:9000/recommend" >> .env
                        '''
                    }
                }
            }
        }

        stage('Build New Version') {
            steps {
                dir("${PROJECT_DIR}") {
                    echo "Building ${env.DEPLOY_COLOR} version..."
                    sh "docker compose -f ${COMPOSE_FILE} build frontend-${env.DEPLOY_COLOR} backend-${env.DEPLOY_COLOR}"
                }
            }
        }

        stage('Start New Containers') {
            steps {
                dir("${PROJECT_DIR}") {
                    echo "Starting ${env.DEPLOY_COLOR} containers..."
                    sh "docker compose -f ${COMPOSE_FILE} up -d frontend-${env.DEPLOY_COLOR} backend-${env.DEPLOY_COLOR}"
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                script {
                    echo "🔄 Switching traffic to ${env.DEPLOY_COLOR}..."
                    sh """
                        cp ${NGINX_CONF_DIR}/nginx-${env.DEPLOY_COLOR}.conf ${NGINX_CONF_DIR}/nginx.conf
                        docker exec ${NGINX_CONTAINER} nginx -s reload
                    """
                }
            }
        }

        stage('Stop Old Containers') {
            steps {
                dir("${PROJECT_DIR}") {
                    echo "Stopping ${env.CURRENT_COLOR} containers..."
                    sh "docker compose -f ${COMPOSE_FILE} stop frontend-${env.CURRENT_COLOR} backend-${env.CURRENT_COLOR}"
                }
            }
        }
    }

    post {
        success {
            echo "✅ Blue–Green Deploy Success! (Now running: ${env.DEPLOY_COLOR})"
        }
        failure {
            echo "❌ Failed! Rolling back to ${env.CURRENT_COLOR}..."
            script {
                sh "docker compose -f ${COMPOSE_FILE} stop frontend-${env.DEPLOY_COLOR} backend-${env.DEPLOY_COLOR} || true"
                sh "cp ${NGINX_CONF_DIR}/nginx-${env.CURRENT_COLOR}.conf ${NGINX_CONF_DIR}/nginx.conf"
                sh "docker exec ${NGINX_CONTAINER} nginx -s reload"
            }
        }
    }
}