FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000

RUN apt-get update && apt-get install -y curl zip bash

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore "open-telemetry-dotnet.csproj"
RUN dotnet build "open-telemetry-dotnet.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "open-telemetry-dotnet.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "open-telemetry-dotnet.dll"]