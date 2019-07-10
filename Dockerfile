FROM nvidia/cuda:latest

RUN mkdir -p /usr/local/bin /patched-lib
COPY patch.sh docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/patch.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
