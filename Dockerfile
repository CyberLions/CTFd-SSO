FROM ghcr.io/ctfd/ctfd:3.8.1 AS build
USER root

WORKDIR /opt/CTFd

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add SSO plugin
RUN git clone https://github.com/CyberLions/CTFd-SSO-plugin CTFd/plugins/CTFd-SSO-plugin

# Add Group plugin
RUN git clone https://github.com/CyberLions/CTFd-Groups-Plugin CTFd/plugins/CTFd-Groups-Plugin

# Add k8s container challenges plugin
RUN git clone https://github.com/CyberLions/ctfd-k8s-challenges /tmp/ctfd-k8s-challenges \
    && mv /tmp/ctfd-k8s-challenges/ctfd-plugin CTFd/plugins/k8s-challenges \
    && rm -rf /tmp/ctfd-k8s-challenges

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt"; \
        fi; \
    done;

FROM ghcr.io/ctfd/ctfd:3.8.1 AS release
WORKDIR /opt/CTFd

# Copy venv with installed dependencies
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
# Copy SSO plugin
COPY --chown=1001:1001 --from=build /opt/CTFd/CTFd/plugins/CTFd-SSO-plugin /opt/CTFd/CTFd/plugins/CTFd-SSO-plugin
# Copy Group plugin
COPY --chown=1001:1001 --from=build /opt/CTFd/CTFd/plugins/CTFd-Groups-Plugin /opt/CTFd/CTFd/plugins/CTFd-Groups-Plugin
# Copy k8s container challenges plugin
COPY --chown=1001:1001 --from=build /opt/CTFd/CTFd/plugins/k8s-challenges /opt/CTFd/CTFd/plugins/k8s-challenges

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
