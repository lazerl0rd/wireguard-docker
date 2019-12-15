FROM alpine:edge

ENV PATH="/scripts:${PATH}"
WORKDIR /scripts

# Install necessary packages
RUN apk add --no-cache \
	wireguard-tools \
	iptables \
	nano \
	net-tools \
	unbound

# Install root certificates and DNSSEC trust anchor
RUN apk add --no-cache ca-certificates; \
	update-ca-certificates; \
	unbound-anchor

# Manage directories/files
RUN mkdir -p \
	/var/cache/stubby

# Copy configuration scripts into WORKDIR
COPY run /scripts
COPY genkeys /scripts

# Configure ownership
RUN chmod +x /scripts/*

CMD ["run"]
