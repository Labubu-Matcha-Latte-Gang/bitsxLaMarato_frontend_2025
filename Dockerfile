FROM ghcr.io/cirruslabs/flutter:3.27.1 AS build

WORKDIR /app

ARG API_URL

COPY . .

RUN flutter pub get

RUN flutter build web --verbose --release --no-tree-shake-icons --dart-define=API_URL=${API_URL:-http://localhost:5000}

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]