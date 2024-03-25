FROM debian:bookworm-slim

# Install needed packages and cleanup after
RUN apt-get -y update && apt-get -y install --no-install-recommends \
 python3-pip \
 vsftpd \
 supervisor \
 s3fs \
 awscli \
 && rm -rf /var/lib/apt/lists/*

# Run commands to set-up everything
RUN mkdir -p /home/aws/s3bucket/ && \
  echo "/usr/sbin/nologin" >> /etc/shells

# Copy scripts to /usr/local
COPY ["s3_fuse.sh", "users.sh", "/usr/local/"]

# Copy needed config files to their destinations
COPY vsftpd.conf /etc/vsftpd.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ftp and sftp ports
EXPOSE 21

# Run supervisord at container start
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
