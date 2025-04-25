# Dựa trên image có sẵn Flutter
FROM cirrusci/flutter:stable

# Set thư mục làm việc
WORKDIR /app

# Copy toàn bộ project vào container
COPY . .

# Build web app
RUN flutter pub get
RUN flutter build web

# Mở port 80
EXPOSE 80

# Chạy web server đơn giản
CMD ["python3", "-m", "http.server", "80", "--directory", "build/web"]
