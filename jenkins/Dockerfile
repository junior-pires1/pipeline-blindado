# Imagem do Jenkins com as ferramentas do Pipeline Blindado já instaladas
FROM jenkins/jenkins:lts-jdk21

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg git python3 python3-pip pipx && \
    # Docker CLI (o daemon é o do host, via /var/run/docker.sock)
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list && \
    # Node.js 22
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends docker-ce-cli nodejs && \
    rm -rf /var/lib/apt/lists/*

# Ferramentas de segurança e deploy
ARG GITLEAKS_VERSION=8.21.2
RUN curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz \
        | tar -xz -C /usr/local/bin gitleaks && \
    curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
    curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin && \
    curl -sSfL -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 && \
    chmod +x /usr/local/bin/cosign && \
    curl -sSfL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash && \
    curl -sSfL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -sSfL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl && \
    PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install semgrep

USER jenkins
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator github-branch-source pipeline-stage-view \
    credentials-binding timestamper junit docker-workflow
