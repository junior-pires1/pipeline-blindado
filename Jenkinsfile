// =====================================================================
//  Pipeline Blindado - CI/CD com DevSecOps (GitHub + Jenkins + K8s)
//  Branches: dev -> homolog -> pre-prod -> main   (sustain = correções)
// =====================================================================
pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        disableConcurrentBuilds()
    }

    environment {
        REGISTRY   = 'ghcr.io'
        IMAGE      = "ghcr.io/SEU-USUARIO-GITHUB/tarefas-api"   // ajuste para o seu usuário
        APP_VER    = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
        SHORT_SHA  = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        TAG        = "${APP_VER}-${BUILD_NUMBER}-${SHORT_SHA}"
        // Ambiente de destino conforme a branch (main = produção)
        AMBIENTE   = "${env.BRANCH_NAME == 'main' ? 'prod' : (env.BRANCH_NAME == 'pre-prod' ? 'preprod' : env.BRANCH_NAME)}"
    }

    stages {

        stage('1. Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.BRANCH_NAME} | Versão: ${TAG} | Ambiente: ${AMBIENTE}"
            }
        }

        // ---------------- PORTÕES DE SEGURANÇA (falham rápido) ----------------
        stage('2. Portão de dependências (typosquatting)') {
            steps {
                // Ataque 2: roda ANTES do npm ci, para que o pacote malicioso nunca seja instalado
                sh 'node scripts/verificar-dependencias.js'
            }
        }

        stage('3. Instalar dependências') {
            steps {
                sh 'npm ci --ignore-scripts --no-fund'
            }
        }

        stage('4. Varredura de segredos') {
            steps {
                // Ataque 1: senha/token comitado por engano é barrado aqui
                // secretlint: arquivos atuais | gitleaks: todo o histórico do Git
                sh 'npx secretlint "**/*"'
                sh 'gitleaks detect --source . --redact --exit-code 1 --report-path gitleaks.json'
            }
        }

        stage('5. Qualidade e SAST') {
            parallel {
                stage('Lint') {
                    steps { sh 'npm run lint' }
                }
                stage('Testes + cobertura') {
                    steps {
                        sh 'node --test --experimental-test-coverage --test-coverage-include="src/**" --test-reporter=spec --test-reporter-destination=stdout --test-reporter=junit --test-reporter-destination=junit.xml test/*.test.js'
                    }
                }
                stage('SAST (Semgrep)') {
                    steps {
                        sh 'semgrep scan --config semgrep.yml --metrics=off --error --json --output semgrep.json src/'
                    }
                }
            }
        }

        stage('6. SCA (vulnerabilidades em dependências)') {
            steps {
                sh 'npm audit --omit=dev --audit-level=high'
            }
        }

        // ---------------- ARTEFATO: construído UMA vez e promovido ----------------
        stage('7. Build da imagem Docker') {
            steps {
                sh "docker build --pull -t ${IMAGE}:${TAG} --label org.opencontainers.image.revision=${SHORT_SHA} ."
            }
        }

        stage('8. Scan da imagem (Trivy)') {
            steps {
                // Reprova se houver vulnerabilidade CRÍTICA (Aula 6 - scan antes do push)
                sh "trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed --no-progress ${IMAGE}:${TAG}"
            }
        }

        stage('9. SBOM (Syft)') {
            steps {
                sh "syft ${IMAGE}:${TAG} -o spdx-json=sbom.spdx.json"
            }
        }

        stage('10. Publicar no registry') {
            when { anyOf { branch 'dev'; branch 'homolog'; branch 'pre-prod'; branch 'main'; branch 'sustain' } }
            steps {
                withCredentials([usernamePassword(credentialsId: 'ghcr-credentials',
                                                  usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh '''
                        echo "$REG_PASS" | docker login ${REGISTRY} -u "$REG_USER" --password-stdin
                        docker push ${IMAGE}:${TAG}
                    '''
                }
                script {
                    // O digest (sha256) é imutável: é ele que vai para o Kubernetes
                    env.DIGEST = sh(script: "docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE}:${TAG} | cut -d@ -f2",
                                    returnStdout: true).trim()
                    echo "Imagem publicada: ${IMAGE}@${env.DIGEST}"
                }
            }
        }

        stage('11. Assinar imagem e anexar SBOM (cosign)') {
            when { anyOf { branch 'dev'; branch 'homolog'; branch 'pre-prod'; branch 'main'; branch 'sustain' } }
            steps {
                withCredentials([file(credentialsId: 'cosign-key', variable: 'COSIGN_KEY'),
                                 string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')]) {
                    sh '''
                        cosign sign --yes --key "$COSIGN_KEY" ${IMAGE}@${DIGEST}
                        cosign attest --yes --key "$COSIGN_KEY" --type spdxjson --predicate sbom.spdx.json ${IMAGE}@${DIGEST}
                    '''
                }
            }
        }

        // ---------------- ENTREGA CONTÍNUA ----------------
        stage('12. Aprovação para produção') {
            when { branch 'main' }
            steps {
                // Continuous Delivery: produção é decisão de negócio (Aula 3)
                timeout(time: 15, unit: 'MINUTES') {
                    input message: "Implantar ${TAG} em PRODUÇÃO?", ok: 'Aprovar deploy'
                }
            }
        }

        stage('13. Deploy com Helm') {
            when { anyOf { branch 'dev'; branch 'homolog'; branch 'pre-prod'; branch 'main' } }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-kind', variable: 'KUBECONFIG')]) {
                    sh '''
                        helm lint helm/tarefas-api -f helm/tarefas-api/values-${AMBIENTE}.yaml
                        helm upgrade --install tarefas-api helm/tarefas-api \
                          --namespace tarefas-${AMBIENTE} --create-namespace \
                          -f helm/tarefas-api/values-${AMBIENTE}.yaml \
                          --set image.repository=${IMAGE} \
                          --set image.digest=${DIGEST} \
                          --set appVersion=${TAG} \
                          --wait --timeout 3m --rollback-on-failure
                    '''
                }
            }
        }

        stage('14. Smoke test') {
            when { anyOf { branch 'dev'; branch 'homolog'; branch 'pre-prod'; branch 'main' } }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-kind', variable: 'KUBECONFIG')]) {
                    sh '''
                        kubectl -n tarefas-${AMBIENTE} run smoke-${BUILD_NUMBER} --rm -i --restart=Never \
                          --image=curlimages/curl:8.10.1 -- \
                          curl -fsS --retry 5 --retry-delay 3 http://tarefas-api/health
                    '''
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'junit.xml'
            archiveArtifacts allowEmptyArchive: true,
                             artifacts: 'gitleaks.json, semgrep.json, sbom.spdx.json, junit.xml'
        }
        failure {
            script {
                // Se o smoke test falhar após o deploy, volta para a revisão anterior
                if (env.DIGEST && ['dev', 'homolog', 'pre-prod', 'main'].contains(env.BRANCH_NAME)) {
                    withCredentials([file(credentialsId: 'kubeconfig-kind', variable: 'KUBECONFIG')]) {
                        sh "helm rollback tarefas-api -n tarefas-${AMBIENTE} || true"
                    }
                }
            }
            echo "PIPELINE REPROVADO na branch ${env.BRANCH_NAME} - nenhuma mudança insegura chegou ao ambiente."
        }
        success {
            echo "PIPELINE APROVADO: ${IMAGE}:${TAG} (${env.DIGEST ?: 'sem publicação'})"
        }
        cleanup {
            sh "docker rmi ${IMAGE}:${TAG} || true"
        }
    }
}
