#!/bin/bash

echo "=== Checking Sink Connection Status ==="
echo ""

# Look for any sink-related activity in the last minute
echo "1. Sink connection logs (last 60s):"
log show --last 60s | grep -i "sink\|cmiosink\|manual discovery\|property listener" | grep -i "gigev" | tail -20

echo ""
echo "2. Checking if app is trying to send frames:"
log show --last 30s | grep -E "Cannot send frame|Queue is full|Sent frame|sendFrame" | tail -10

echo ""
echo "3. Current process PIDs:"
ps aux | grep -E "GigE" | grep -v grep | awk '{print $2 " - " $11}'