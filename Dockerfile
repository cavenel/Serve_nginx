FROM nginx:1.27-alpine

# SciLifeLab Serve runs containers as a non-root user with UID 1000.
RUN adduser -D -u 1000 serve

WORKDIR /home/serve

COPY nginx.conf /etc/nginx/nginx.conf
COPY --chown=1000:1000 start-script.sh ./start-script.sh

# Serve mounts the project volume at /home/data. That directory must not exist
# in the image, otherwise the mount does not show up and nginx serves the
# image contents instead. Nothing is copied there.

RUN chmod +x ./start-script.sh \
 && chown -R 1000:1000 /home/serve

USER 1000
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1

ENTRYPOINT ["./start-script.sh"]
