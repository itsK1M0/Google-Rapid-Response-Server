#!/bin/bash
# stop_grr_services.sh
# Script to stop GRR, Fleetspeak, and MySQL services in order with delays
# and show their status afterwards

echo "Stopping GRR server..."
sudo systemctl stop grr-server
sleep 5

echo "Stopping Fleetspeak server..."
sudo systemctl stop fleetspeak-server.service
sleep 5

echo "Stopping MySQL server..."
sudo systemctl stop mysql
sleep 5

echo "Syncing filesystem..."
sync

echo
echo "Checking service statuses..."

echo "GRR server status:"
sudo systemctl status grr-server --no-pager | grep -E "Active:|Loaded:"
echo

echo "Fleetspeak server status:"
sudo systemctl status fleetspeak-server.service --no-pager | grep -E "Active:|Loaded:"
echo

echo "MySQL server status:"
sudo systemctl status mysql.service --no-pager | grep -E "Active:|Loaded:"
echo

echo "All services stopped. Status check complete."

