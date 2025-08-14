FROM alpine:3.21

ENV LANG=C.UTF-8
ENV CHROME_BIN=/usr/bin/chromium-browser
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    musl-dev \
    python3-dev \
    libffi-dev \
    openssl-dev \
    cargo \
    rust \
    bash \
    curl \
    jq \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --upgrade pip --break-system-packages && \
    pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Copy all application files
COPY . .

# Create run.sh directly in Dockerfile if it doesn't exist properly
RUN echo '#!/bin/bash' > /run.sh && \
    echo 'if [ -f /data/options.json ]; then' >> /run.sh && \
    echo '    export MQTT_BROKER=$(jq -r ".mqtt_broker // \"core-mosquitto\"" /data/options.json)' >> /run.sh && \
    echo '    export MQTT_PORT=$(jq -r ".mqtt_port // 1883" /data/options.json)' >> /run.sh && \
    echo '    export MQTT_USERNAME=$(jq -r ".mqtt_username // \"sml2mqtt\"" /data/options.json)' >> /run.sh && \
    echo '    export MQTT_PASSWORD=$(jq -r ".mqtt_password // \"sml2mqttPassword\"" /data/options.json)' >> /run.sh && \
    echo '    export UPDATE_INTERVAL=$(jq -r ".update_interval // 300" /data/options.json)' >> /run.sh && \
    echo '    echo $(jq -r ".secrets // {}" /data/options.json) >> auth/secrets.json' >> /run.sh && \
    echo 'else' >> /run.sh && \
    echo '    export MQTT_BROKER="core-mosquitto"' >> /run.sh && \
    echo '    export MQTT_PORT="1883"' >> /run.sh && \
    echo '    export MQTT_USERNAME="sml2mqtt"' >> /run.sh && \
    echo '    export MQTT_PASSWORD="sml2mqttPassword"' >> /run.sh && \
    echo '    export UPDATE_INTERVAL="300"' >> /run.sh && \
    echo 'fi' >> /run.sh && \
    echo 'echo "Starting Google Find My Tools..."' >> /run.sh && \
    echo 'echo "MQTT Broker: $MQTT_BROKER"' >> /run.sh && \
    echo 'cd /app' >> /run.sh && \
    echo 'while true; do' >> /run.sh && \
    echo '    echo "$(date): Running Google Find My update..."' >> /run.sh && \
    echo '    python3 publish_mqtt.py' >> /run.sh && \
    echo '    if [ $? -eq 0 ]; then' >> /run.sh && \
    echo '        echo "$(date): Update completed successfully"' >> /run.sh && \
    echo '    else' >> /run.sh && \
    echo '        echo "$(date): Update failed with exit code $?"' >> /run.sh && \
    echo '    fi' >> /run.sh && \
    echo '    echo "$(date): Sleeping for $UPDATE_INTERVAL seconds..."' >> /run.sh && \
    echo '    sleep "$UPDATE_INTERVAL"' >> /run.sh && \
    echo 'done' >> /run.sh && \
    chmod +x /run.sh

CMD ["/run.sh"]