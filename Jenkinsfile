pipeline {
    agent { label 'jenkins-agent' }

    options {
        ansiColor('xterm')
    }
    // Paramaetros
    parameters {
        choice(
            choices: [
                'default',
                'update_scm',
                'build_image',
                'main_plan',
                'main_refresh',
                'main_destroy',
            ],
            description: "Angular Pipeline action to apply",
            name: 'action'
        )

        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generation plan?')
        string(name: 'SECRET_NAME', defaultValue: params.SECRET_NAME ?: 'kevin-key-sa', description: 'AWS Secret')

        string(name: 'AWS_REGION', defaultValue: params.AWS_REGION ?: 'eu-central-1', description: 'AWS Region')
        string(name: 'EKS_CLUSTER_NAME', defaultValue: params.EKS_CLUSTER_NAME ?: 'infra-syndeno', description: 'Cluster Name (must be a domain)')

        string(name: 'ANGULAR_NAMESPACE', defaultValue: params.ANGULAR_NAMESPACE ?: 'angular', description: 'Namespace for Angular')
        string(name: 'ANGULAR_IMAGE', defaultValue: params.ANGULAR_IMAGE ?: 'kevinorellana/angular', description: 'Name image')
        string(name: 'ANGULAR_IMAGE_TAG', defaultValue: params.ANGULAR_IMAGE_TAG ?: 'v1', description: 'Tag image')
    }

    environment {
        TF_OUTPUT="$WORKSPACE/terraform.output"

        TF_VAR_namespace="${env.ANGULAR_NAMESPACE}"

        TF_VAR_region="${env.AWS_REGION}"
        TF_VAR_cluster_name="${env.EKS_CLUSTER_NAME}"

        TF_VAR_angular_image="${env.ANGULAR_IMAGE}"
        TF_VAR_angular_image_tag="${env.ANGULAR_IMAGE_TAG}"
    }

    stages {

        stage('Get AWS Credentials') {
            when {
                expression {
                    params.action == 'default' ||
                    params.action == 'update_scm' ||
                    params.action == 'build_image' ||
                    params.action == 'main_plan' ||
                    params.action == 'main_refresh' ||
                    params.action == 'main_destroy'    
                }
            }
            steps{
                script{
                    withCredentials([file(credentialsId: env.SECRET_NAME, variable: 'key')]){
                        sh """
                            mkdir -p $WORKSPACE/.aws
                            mkdir -p $WORKSPACE/.ssh
                            mkdir -p $WORKSPACE/.kube
                            chmod 700 $WORKSPACE/.ssh

                            env || sort

                            aws --version
                            cat ${key}
                            aws configure import --csv file://${key}
                            aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
                        """
                    }
                }
            }
        }

        stage('Build Image'){
            when {
                expression {
                    params.action == 'pull_images'
                }
            }
            steps {
                sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                    docker build -t ${TF_VAR_angular_image}:${TF_VAR_angular_image_tag} -f images/Dockerfile .
                """.stripIndent())
            }
        }

        stage('Main Init') {
            when {
                expression {
                    params.action == 'default' ||
                    params.action == 'update_scm' ||
                    params.action == 'build_image' ||
                    params.action == 'main_plan' ||
                    params.action == 'main_refresh' ||
                    params.action == 'main_destroy'
                }
            }
            steps {
                sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                    terraform version
                    terraform init -reconfigure
                """)
            }
        }

        stage('Main Plan') {
            when {
                expression {
                    params.action == 'default' ||
                    params.action == 'main_plan'
                }
            }
            steps {
                script {
                sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                    env | sort
                    terraform plan -input=false -lock=false -out tfplan && \
                    terraform show -no-color tfplan > tfplan.txt
                """.stripIndent())
                }
            }
        }

        stage('Main Refresh') {
            when {
                expression {
                    params.action == 'main_refresh'
                }
            }
            steps {
                script {
                    sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                        terraform apply -refresh-only -input=false -lock=false -out tfplan && \
                        terraform show -no-color tfplan > tfplan.txt
                    """.stripIndent())
                }
            }
        }

        stage('Main Destroy') {
            when {
                expression {
                    params.action == 'main_destroy'
                }
            }
            steps {
                script {
                    sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                        terraform plan -destroy -input=false -lock=false -out tfplan && \
                        terraform show -no-color tfplan > tfplan.txt
                    """.stripIndent())
                }
            }
        }

        stage('Main Approve') {
            when {
                expression {
                    params.action == 'default' ||
                    params.action == 'main_plan' ||
                    params.action == 'main_refresh' ||
                    params.action == 'main_destroy'
                }
                not {
                    equals expected: true, actual: params.autoApprove
                }
            }
            steps {
                script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan?",
                        parameters: [text(name: 'Plan', description:'Please review the plan', defaultValue: plan)]
                }
            }
        }

        stage('Main Apply') {
            when {
                expression {
                    params.action == 'default' ||
                    params.action == 'main_plan' ||
                    params.action == 'main_refresh' ||
                    params.action == 'main_destroy'
                }
            }
            steps {
                sh(returnStdout: false, returnStatus:true, script: """#!/bin/bash
                    terraform apply -input=false -lock=false tfplan && \
                    terraform show
                """.stripIndent())
            }
        }
    }
}