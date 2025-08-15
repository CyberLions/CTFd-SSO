FROM ghcr.io/ctfd/ctfd:3.7.7 as build
USER root

WORKDIR /opt/CTFd

RUN apt-get update 
RUN apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git 
RUN apt-get clean

# Add SSO plugin:
RUN git clone https://github.com/CyberLions/CTFd-SSO-plugin CTFd/plugins/CTFd-SSO-plugin

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;

# Add k8s plugin:
RUN git clone https://github.com/CyberLions/CTFd-k8s-challenge-plugin CTFd/plugins/CTFd-k8s-challenge-plugin

RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
        if [ -f "$d/requirements.txt" ]; then \
            pip install --no-cache-dir -r "$d/requirements.txt";\
        fi; \
    done;

FROM ghcr.io/ctfd/ctfd:3.7.7 as release
WORKDIR /opt/CTFd

# Copy VENV
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
# Copy SSO plugin
COPY --chown=1001:1001 --from=build /opt/CTFd/CTFd/plugins/CTFd-SSO-plugin /opt/CTFd/CTFd/plugins/CTFd-SSO-plugin
# Copy k8s plugin
COPY --chown=1001:1001 --from=build /opt/CTFd/CTFd/plugins/CTFd-k8s-challenge-plugin /opt/CTFd/CTFd/plugins/CTFd-k8s-challenge-plugin

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
