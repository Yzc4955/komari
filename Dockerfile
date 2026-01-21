# 构建阶段
FROM node:23-alpine AS frontend-builder

WORKDIR /app

# 克隆前端代码
RUN apk add --no-cache git && \
    git clone https://github.com/komari-monitor/komari-web web

# 构建前端
WORKDIR /app/web
RUN npm install && npm run build

# 后端构建阶段
FROM golang:1.23-alpine AS backend-builder

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git tzdata

# 复制前端构建产物
COPY --from=frontend-builder /app/web/dist /app/public/dist

# 复制后端代码
COPY . /app

# 构建后端
RUN go build -trimpath -ldflags="-s -w" -o komari main.go

# 运行阶段
FROM alpine:3.21

WORKDIR /app

# 安装依赖
RUN apk add --no-cache tzdata

# 复制构建产物
COPY --from=backend-builder /app/komari /app/komari
COPY --from=backend-builder /app/public /app/public

# 设置权限
RUN chmod +x /app/komari

# 创建数据目录
RUN mkdir -p /app/data

# 环境变量
ENV GIN_MODE=release
ENV KOMARI_DB_TYPE=sqlite
ENV KOMARI_DB_FILE=/app/data/komari.db
ENV KOMARI_DB_HOST=localhost
ENV KOMARI_DB_PORT=3306
ENV KOMARI_DB_USER=root
ENV KOMARI_DB_PASS=
ENV KOMARI_DB_NAME=komari
ENV KOMARI_LISTEN=0.0.0.0:25774

EXPOSE 25774

CMD ["/app/komari", "server"]