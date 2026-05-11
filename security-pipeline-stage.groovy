stage('Advanced Security Scan') {
    parallel {
        stage('Vulnerability Scan') {
            steps {
                echo 'Running Trivy vulnerability scan...'
                sh '''
                    ./security-scan.sh ${DOCKER_IMAGE}:${BUILD_NUMBER} json HIGH,CRITICAL
                    
                    # Archive security reports
                    mkdir -p reports
                    cp reports/security-report.* . || true
                '''
                
                // Archive reports
                archiveArtifacts artifacts: 'security-report.*', allowEmptyArchive: true
                
                // Publish security report
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'reports',
                    reportFiles: 'security-report.txt',
                    reportName: 'Security Scan Report'
                ])
            }
        }
        
        stage('Container Compliance') {
            steps {
                echo 'Checking container compliance...'
                sh '''
                    # Check if container runs as non-root
                    docker run --rm ${DOCKER_IMAGE}:${BUILD_NUMBER} whoami | grep -v root || echo "WARNING: Container runs as root"
                    
                    # Check for security best practices
                    docker history ${DOCKER_IMAGE}:${BUILD_NUMBER} --no-trunc | grep -i "add\|copy" | wc -l
                '''
            }
        }
    }
}
