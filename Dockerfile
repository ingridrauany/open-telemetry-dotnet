FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

RUN apt-get update && apt-get install -y curl zip bash
RUN mkdir /otel
RUN curl -L -o /otel/otel-dotnet-install.sh https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v1.4.0/otel-dotnet-auto-install.sh
RUN chmod +x /otel/otel-dotnet-install.sh

# Configure OpenTelemetry Enviroment Vars
ENV OTEL_DOTNET_AUTO_HOME=/otel
ENV OTEL_METRICS_EXPORTER=otlp
ENV OTEL_LOGS_EXPORTER=otlp
ENV OTEL_TRACES_EXPORTER=otlp

RUN /bin/bash /otel/otel-dotnet-install.sh

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore "open-telemetry-dotnet.csproj"
RUN dotnet build "open-telemetry-dotnet.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "open-telemetry-dotnet.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
COPY --from=publish /app/publish .

ENTRYPOINT ["/bin/bash", "-c", "source /otel/instrument.sh && dotnet open-telemetry-dotnet.dll"]