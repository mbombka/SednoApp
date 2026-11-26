# Use stage.py to prepare the build context.
FROM golang:1.26-bookworm@sha256:ea47ee45f1284d60f9cc09cb2c3bb4f508c256b640bd8bb30342ff13d1adcb52 AS launcher
WORKDIR /src
COPY main.go .
RUN CGO_ENABLED=0 go build -trimpath -o /out/startup-phases main.go

FROM mcr.microsoft.com/dotnet/sdk:10.0@sha256:8c6edfb26c85153f236d26efebd9ad349aec403583f343f201ee67838b23658d AS build
WORKDIR /src
COPY backend/src backend/src
COPY docs/public/prywatnosc/index.html docs/public/prywatnosc/index.html
RUN dotnet publish backend/src/Sedno.Api -c Release -r linux-x64 --self-contained false -o /out \
    -p:UseAppHost=false -p:PublishReadyToRun=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0@sha256:aac50ceef10391e78a899e3d2ccd00bbafa2dcb56ccf4586cbccf00edb84fc21
WORKDIR /app
COPY --from=build /out/ .
COPY --from=launcher /out/startup-phases /app/startup-phases
ENV ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_HTTP_PORTS=8080
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["/app/startup-phases"]
CMD ["sedno"]
