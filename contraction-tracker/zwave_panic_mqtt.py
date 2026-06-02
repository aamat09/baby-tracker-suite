#!/usr/bin/env python3
"""
Z-Wave JS UI WebSocket → MQTT bridge for Ring Panic Button Gen 2 (node 20).
Listens for Emergency Alarm / Panic alert notifications and publishes to MQTT.
"""
import json, time, threading, logging
import urllib.request
import websocket
import paho.mqtt.client as mqtt

ZWAVE_WS   = "ws://homelab.local:3000"
MQTT_HOST  = "homelab.local"
MQTT_PORT  = 1883
MQTT_USER  = "aamat"
MQTT_PASS  = "exploracion"
MQTT_TOPIC  = "zwave/node_20/panic"
N8N_WEBHOOK = "http://homelab.local:5678/webhook/contraction-panic"
PANIC_NODE  = 20

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
log = logging.getLogger("panic-bridge")

mqttc = mqtt.Client(client_id="zwave-panic-bridge")
mqttc.username_pw_set(MQTT_USER, MQTT_PASS)

def mqtt_connect():
    while True:
        try:
            mqttc.connect(MQTT_HOST, MQTT_PORT, keepalive=60)
            mqttc.loop_start()
            log.info("MQTT connected")
            return
        except Exception as e:
            log.warning(f"MQTT connect failed: {e}, retrying in 5s")
            time.sleep(5)

def on_ws_message(ws, raw):
    try:
        msg = json.loads(raw)
    except Exception:
        return

    if msg.get("type") != "event":
        return

    event = msg.get("event", {})
    node_id = event.get("nodeId") or event.get("node", {}).get("nodeId")
    event_name = event.get("event") or event.get("eventName", "")

    if node_id != PANIC_NODE:
        return

    # event="notification" with notificationLabel="Panic alert"
    if event.get("event") == "notification" and "panic" in event.get("notificationLabel", "").lower():
        payload = json.dumps({"node": PANIC_NODE, "event": "panic", "ts": time.time()})
        mqttc.publish(MQTT_TOPIC, payload, qos=1, retain=False)
        try:
            req = urllib.request.Request(N8N_WEBHOOK, data=payload.encode(), headers={"Content-Type": "application/json"}, method="POST")
            urllib.request.urlopen(req, timeout=5)
        except Exception as e:
            log.warning(f"n8n webhook failed: {e}")
        log.info(f"PANIC published → {MQTT_TOPIC} + n8n webhook")

def on_ws_open(ws):
    log.info("WebSocket connected to Z-Wave JS UI")
    def _subscribe():
        time.sleep(0.3)
        ws.send(json.dumps({"messageId": "sl", "command": "start_listening", "schemaVersion": 44}))
    threading.Thread(target=_subscribe, daemon=True).start()

def on_ws_error(ws, err):
    log.error(f"WebSocket error: {err}")

def on_ws_close(ws, code, msg):
    log.warning(f"WebSocket closed ({code}), reconnecting in 5s")

def run():
    mqtt_connect()
    while True:
        ws = websocket.WebSocketApp(
            ZWAVE_WS,
            on_open=on_ws_open,
            on_message=on_ws_message,
            on_error=on_ws_error,
            on_close=on_ws_close,
        )
        ws.run_forever(ping_interval=30, ping_timeout=10)
        time.sleep(5)

if __name__ == "__main__":
    run()
