pipeline {
    agent any

    stages {
        stage('Build Jenkins image') {
            steps {
                sh 'make build-jenkins'
            }
        }

        stage('Build home latest image') {
            steps {
                sh 'make build-latest'
            }
        }
    }
}
