# Build from the repository root: docker build -f backend/Dockerfile .
FROM golang:1.26.11-bookworm AS build
WORKDIR /src
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/cmd ./cmd
COPY backend/internal ./internal
COPY backend/src/Sedno.Infrastructure/Prompts ./src/Sedno.Infrastructure/Prompts
COPY docs/public/prywatnosc/index.html /out/privacy.html
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/sedno ./cmd/sedno \
    && chmod 0555 /out/sedno \
    && chmod 0444 /out/privacy.html

FROM scratch
WORKDIR /app
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/sedno /app/sedno
COPY --from=build /out/privacy.html /app/privacy.html
ENV ASPNETCORE_ENVIRONMENT=Production SEDNO_PRIVACY_PATH=/app/privacy.html
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/app/sedno"]
