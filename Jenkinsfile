pipeline {
    agent any
    // Poll SCM every 2 minutes
    triggers {
        pollSCM('H/2 * * * *')
    }
    environment {
        // default if TaskID not found in commit message
        DEFAULT_TASK = 'Task-1'
    }
    stages {
        stage('Checkout') {
            steps {
                // Checkout the specified repository directly (change branch if needed)
                // Use the GitHub token credential 'gh_token' to authenticate cloning the private repo
                checkout([$class: 'GitSCM', branches: [[name: '*/main']], doGenerateSubmoduleConfigurations: false, extensions: [], userRemoteConfigs: [[url: 'https://github.com/DBMaestroDev/source-control-example.git', credentialsId: 'gh_token']]])
            }
        }

        stage('Detect TaskID') {
            steps {
                script {
                    // Get the most recent commit message
                    def commitMsg = powershell(returnStdout: true, script: 'git --no-pager log -1 --pretty=%B').trim()
                    echo "Commit message:\n${commitMsg}"

                    // Look for a line containing: TaskID: <value>
                    def matcher = (commitMsg =~ /(?m)TaskID:\s*(\S+)/)
                    if (matcher) {
                        env.TASK_ID = matcher[0][1]
                        echo "Found TaskID: ${env.TASK_ID}"
                    } else {
                        env.TASK_ID = env.DEFAULT_TASK
                        echo "No TaskID found in commit message; using default: ${env.TASK_ID}"
                    }
                }
            }
        }

        stage('Run DBmaestro Agent') {
            steps {
                // Run the requested PowerShell command, substituting the detected TASK_ID
                powershell """
                java -jar DBmaestroAgent.jar -Build -ProjectName "DemoProject" -EnvName "Dev_Env_1" -VersionType "Tasks" -AdditionalInformation "${env.TASK_ID}" -CreatePackage True -PackageName "Package-2" -Server "DELL-NICOLAST:8017" -UseSSL True -AuthType DBmaestroAccount -UserName "su@dbmaestro.local" -Password "d5BfNaR6s7fIGT5Sj2oVWQDYQhetkNfh"
                """
            }
        }
    }
    post {
        always {
            echo "Completed pipeline. TASK_ID=${env.TASK_ID}"
        }
    }
}
