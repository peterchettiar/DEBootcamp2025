#!/bin/bash
set -e

# Wait for the server to start
echo "[INFO] Waiting for PostgreSQL to be ready..."
until pg_isready -U "$POSTGRES_USER"; do
  sleep 1
done

# Only restore if the DB is empty (to prevent duplicate restores)
if [ "$(psql -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';")" = "0" ]; then
  echo "[INFO] Restoring database from data.dump..."
  pg_restore -v --no-owner --no-privileges -U "$POSTGRES_USER" -d "$POSTGRES_DB" /docker-entrypoint-initdb.d/data.dump
  echo "[SUCCESS] Restore complete."
else
  echo "[INFO] Database already initialized, skipping restore."
fi
