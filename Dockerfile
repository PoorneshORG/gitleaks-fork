# Stage 1: Build the gitleaks binary
FROM golang:1.23.10-alpine3.21 AS builder

ENV GOTOOLCHAIN=auto

WORKDIR /app

# Install git for cloning and build-time dependencies
RUN apk add --no-cache git

# Clone custom fork of gitleaks
ARG GH_TOKEN
RUN git clone --branch main https://${GH_TOKEN}@github.com/Adaptavant/DevOps-Secret-Scans.git .
RUN go build -o /app/bin/gitleaks .
RUN chmod +x /app/bin/gitleaks

# Stage 2: Create a minimal runtime image
FROM alpine:3.21

# Install runtime dependencies: git (required by gitleaks), and certs
RUN apk add --no-cache git ca-certificates file libc6-compat

# Copy gitleaks binary and config from the builder stage
COPY --from=builder /app/bin/gitleaks /usr/local/bin/gitleaks

COPY --from=builder /app/config/gitleaks.toml /etc/gitleaks.toml

# 🔧 Fix permission issue
RUN chmod +x /usr/local/bin/gitleaks
RUN ls -l /usr/local/bin/gitleaks && file /usr/local/bin/gitleaks

# Optional: verify the binary works
RUN /usr/local/bin/gitleaks version

# Set default entrypoint
ENTRYPOINT ["gitleaks"]