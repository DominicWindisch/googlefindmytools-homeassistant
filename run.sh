  GNU nano 8.4                                                                                                      run.sh                                                                                                                
#!/bin/bash

# Read configuration from options.json (Home Assistant add-on config)
if [ -f /data/options.json ]; then
    export MQTT_BROKER=$(jq -r '.mqtt_broker // "core-mosquitto"' /data/options.json)
    export MQTT_PORT=$(jq -r '.mqtt_port // 1883' /data/options.json)
    export MQTT_USERNAME=$(jq -r '.mqtt_username // "sml2mqtt"' /data/options.json)
    export MQTT_PASSWORD=$(jq -r '.mqtt_password // "sml2mqttPassword"' /data/options.json)
    export UPDATE_INTERVAL=$(jq -r '.update_interval // 300' /data/options.json)
else
    export MQTT_BROKER="core-mosquitto"
    export MQTT_PORT="1883"
    export MQTT_USERNAME="sml2mqtt"
    export MQTT_PASSWORD="sml2mqttPassword"
    export UPDATE_INTERVAL="300"
fi

echo "Starting Google Find My Tools..."
echo "MQTT Broker: $MQTT_BROKER"
echo "MQTT Port: $MQTT_PORT"
echo "Update interval: $UPDATE_INTERVAL seconds"

cd /app

while true; do
    echo "$(date): Running Google Find My update..."
    python3 publish_mqtt.py

    if [ $? -eq 0 ]; then
        echo "$(date): Update completed successfully"
    else
        echo "$(date): Update failed with exit code $?"
    fi

    echo "$(date): Sleeping for $UPDATE_INTERVAL seconds..."
    sleep "$UPDATE_INTERVAL"
done
