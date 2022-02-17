/* import shared library. */
@Library('chocoapp-slack-share-library')_

pipeline {
    environment {
        IMAGE_NAME = "ic-webapp"
        APP_CONTAINER_PORT = "8080"
        APP_EXPOSED_PORT = "8000"
        IMAGE_TAG = "v1.0" /* Metttre les tags comme paramètre du job a fournir lors du lancement*/
        DOCKERHUB_ID = "choco1992"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
        DOCKERFILE_NAME = "Dockerfile_v1.0" /* A metttre comme paramètre du job a fournir lors du lancement*/
        ANSIBLE_IMAGE_AGENT = "registry.gitlab.com/robconnolly/docker-ansible:latest"
    }
    agent none
    stages {
       stage('Build image') {
           agent any
           steps {
              script {
                sh 'docker build --no-cache -f ./sources/app/${DOCKERFILE_NAME} -t ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG ./sources/app'
                
              }
           }
       }
       stage('Run container based on builded image') {
          agent any
          steps {
            script {
              sh '''
                  echo "Cleaning existing container if exist"
                  docker ps -a | grep -i $IMAGE_NAME && docker rm -f ${IMAGE_NAME}
                  docker run --name ${IMAGE_NAME} -d -p $APP_EXPOSED_PORT:$APP_CONTAINER_PORT  ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
                  sleep 5
              '''
             }
          }
       }
       stage('Test image') {
           agent any
           steps {
              script {
                sh '''
                   curl -I http://${HOST_IP}:${APP_EXPOSED_PORT} | grep -i "200"
                '''
              }
           }
       }
       stage('Clean container') {
          agent any
          steps {
             script {
               sh '''
                   docker stop $IMAGE_NAME
                   docker rm $IMAGE_NAME
               '''
             }
          }
      }

      stage ('Login and Push Image on docker hub') {
          agent any
          steps {
             script {
               sh '''
                   echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_ID --password-stdin
                   docker push ${DOCKERHUB_ID}/$IMAGE_NAME:$IMAGE_TAG
               '''
             }
          }
      }

      stage ('Prepare ansible environment') {
          agent any
          environment {
            VAULT_KEY = credentials('vault_key')
            PRIVATE_KEY = credentials('private_key')
          }          
          steps {
             script {
               sh '''
                  echo $VAULT_KEY > vault.key
                  echo $PRIVATE_KEY > id_rsa
                  chmod 600 id_rsa
               '''
             }
          }
      }

      stage('Deploy application ') {
        agent { docker { image 'registry.gitlab.com/robconnolly/docker-ansible:latest'  } }
        stages {
            stage ("Install Ansible role dependencies") {
                steps {
                    script {
                        sh 'echo launch ansible-galaxy install -r roles/requirement.yml if needed'
                    }
                }
            }

            stage ("Ping  targeted hosts") {
                steps {
                    script {
                        sh 'ansible all -m ping --private-key \${WORKSPACE}/id_rsa'
                    }
                }
            }

            stage ("Check playbook syntax") {
                steps {
                    script {
                        sh '''
                            echo ansible-lint -x 306 sources/playbooks/install-docker.yml
                            echo ${GIT_BRANCH}
                                                
                        '''
                    }
                }
            }
            
            stage ("Deploy in PRODUCTION") {
                when { expression { GIT_BRANCH == 'origin/main'} }                
                stages {
                    stage ("PRODUCTION - Install Docker all target hosts") {
                        steps {
                            script {
                                sh '''
                                    apt update -y
                                    apt install sshpass -y
                                    cd sources/ansible-ressources && ansible-playbook playbooks/install-docker.yml --vault-password-file \${WORKSPACE}/vault.key --private-key \${WORKSPACE}/id_rsa -l prod
                                '''
                            }
                        }
                    }

                    stage ("PRODUCTION - deploy pgadmin") {
                        steps {
                            script {
                                sh 'cd sources/ansible-ressources && ansible-playbook playbooks/deploy-pgadmin.yml --vault-password-file \${WORKSPACE}/vault.key --private-key \${WORKSPACE}/id_rsa -l pg_admin'
                            }
                        }
                    }
                    stage ("PRODUCTION - deploy odoo") {
                        steps {
                            script {
                                sh 'cd sources/ansible-ressources && ansible-playbook playbooks/deploy-odoo.yml --vault-password-file \${WORKSPACE}/vault.key --private-key \${WORKSPACE}/id_rsa -l odoo'
                            }
                        }
                    }

                    stage ("PRODUCTION - deploy ic-webapp") {
                        steps {
                            script {
                                sh 'cd sources/ansible-ressources && ansible-playbook playbooks/deploy-ic-webapp.yml --vault-password-file \${WORKSPACE}/vault.key --private-key \${WORKSPACE}/id_rsa -l ic_webapp'
                            }
                        }
                    }


                }
            }

/*          stage ("Deploy in DEV") {
                stages {
                    stage ("DEV - Install Docker all target hosts") {
                        steps {
                            script {
                                sh '''
                                    ansible-playbook sources/ansible-ressources/playbooks/install-docker.yml --vault-password-file vault.key --private-key id_rsa -l dev
                                                        
                                '''
                            }
                        }
                    }

                    stage ("DEV - deploy pgadmin") {
                        steps {
                            script {
                                sh '''
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-pgadmin.yml --vault-password-file vault.key --private-key id_rsa -l pg_admin_dev
                                                        
                                '''
                            }
                        }
                    }
                    stage ("PRODUCTION - deploy odoo") {
                        steps {
                            script {
                                sh '''
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-odoo.yml --vault-password-file vault.key --private-key id_rsa -l odoo_dev
                                                        
                                '''
                            }
                        }
                    }

                    stage ("PRODUCTION - deploy ic-webapp") {
                        steps {
                            script {
                                sh '''
                                    ansible-playbook sources/ansible-ressources/playbooks/deploy-ic-webapp.yml --vault-password-file vault.key --private-key id_rsa -l ic_webapp_dev
                                                        
                                '''
                            }
                        }
                    }


                }
            } */

        }

      }
    }

/*  post {
     always {
       script {
         slackNotifier currentBuild.result
       }
     }
    }*/
}