# Etapa 1: compilar la app Flutter Web
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor
RUN flutter config --enable-web

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release

# Etapa 2: servir los archivos compilados con nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80