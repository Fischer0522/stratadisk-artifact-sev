#!/bin/bash

# Script to initialize and manage PostgreSQL instances on SwornDisk/CryptDisk
# Each instance is independent with its own data directory

set -e

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
NC='\033[0m'

# Configuration
DATA_DIR="/home/yxy/ssd/fast26_ae/sev/data"
SWORNDISK_DIR="${DATA_DIR}/sworndisk-postgres"
CRYPTDISK_DIR="${DATA_DIR}/cryptdisk-postgres"
POSTGRES_USER="postgres"

# Port configuration (to avoid conflict with system PostgreSQL)
SWORNDISK_PORT=5433
CRYPTDISK_PORT=5434

# Detect PostgreSQL version
POSTGRES_VERSION=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1 || echo "")

if [ -z "$POSTGRES_VERSION" ]; then
    echo -e "${RED}Error: PostgreSQL is not installed${NC}"
    echo "Please install PostgreSQL first:"
    echo "  sudo apt update"
    echo "  sudo apt install -y postgresql postgresql-contrib"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}PostgreSQL Instance Manager${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "PostgreSQL Version: ${POSTGRES_VERSION}"
echo ""

# Function to initialize a new PostgreSQL instance
init_instance() {
    local name=$1
    local data_dir=$2
    local port=$3
    local instance_cmd=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Initializing PostgreSQL for ${name}${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""
    echo "Data Directory: ${data_dir}"
    echo "Port: ${port}"
    echo ""

    # Create directory
    echo -e "${YELLOW}[1/4] Creating data directory...${NC}"
    mkdir -p "${data_dir}"

    # Check if already initialized
    if [ -f "${data_dir}/PG_VERSION" ]; then
        echo -e "${YELLOW}PostgreSQL instance already initialized in ${data_dir}${NC}"
        echo "Skipping initialization."
        return 0
    fi

    # Set ownership (if running as root)
    if [ "$EUID" -eq 0 ]; then
        chown -R ${POSTGRES_USER}:${POSTGRES_USER} "${data_dir}"
        echo -e "${GREEN}✓ Directory created and ownership set${NC}"
    else
        echo -e "${GREEN}✓ Directory created${NC}"
    fi
    echo ""

    # Initialize database cluster
    echo -e "${YELLOW}[2/4] Initializing database cluster...${NC}"
    if [ "$EUID" -eq 0 ]; then
        sudo -u ${POSTGRES_USER} /usr/lib/postgresql/${POSTGRES_VERSION}/bin/initdb -D "${data_dir}"
    else
        /usr/lib/postgresql/${POSTGRES_VERSION}/bin/initdb -D "${data_dir}"
    fi
    echo -e "${GREEN}✓ Database cluster initialized${NC}"
    echo ""

    # Configure PostgreSQL
    echo -e "${YELLOW}[3/4] Configuring PostgreSQL...${NC}"

    # Update port
    sed -i "s/#port = 5432/port = ${port}/" "${data_dir}/postgresql.conf"

    # Update listen_addresses to allow connections
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${data_dir}/postgresql.conf"

    # Update socket directory to avoid conflicts
    mkdir -p "${data_dir}/run"
    sed -i "s|#unix_socket_directories = '/var/run/postgresql'|unix_socket_directories = '${data_dir}/run'|" "${data_dir}/postgresql.conf"

    echo -e "${GREEN}✓ Configuration updated${NC}"
    echo "  Port: ${port}"
    echo "  Socket: ${data_dir}/run"
    echo ""

    # Set permissions
    echo -e "${YELLOW}[4/4] Setting permissions...${NC}"
    chmod 700 "${data_dir}"
    if [ "$EUID" -eq 0 ]; then
        chown -R ${POSTGRES_USER}:${POSTGRES_USER} "${data_dir}"
    fi
    echo -e "${GREEN}✓ Permissions set${NC}"
    echo ""

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Initialization complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start the instance: $0 start ${instance_cmd}"
    echo "  2. Initialize YCSB database: $0 init-ycsb ${instance_cmd}"
    echo ""
}

# Function to start PostgreSQL instance
start_instance() {
    local name=$1
    local data_dir=$2
    local port=$3
    local instance_cmd=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    echo -e "${YELLOW}Starting PostgreSQL instance: ${name}${NC}"
    echo "Data Directory: ${data_dir}"
    echo "Port: ${port}"
    echo ""

    if [ ! -f "${data_dir}/PG_VERSION" ]; then
        echo -e "${RED}Error: PostgreSQL instance not initialized${NC}"
        echo "Run: $0 init ${instance_cmd}"
        return 1
    fi

    # Check if already running
    if [ -f "${data_dir}/postmaster.pid" ]; then
        echo -e "${YELLOW}Instance appears to be already running${NC}"
        local pid=$(head -1 "${data_dir}/postmaster.pid")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${GREEN}PostgreSQL is running (PID: ${pid})${NC}"
            return 0
        else
            echo -e "${YELLOW}Removing stale PID file...${NC}"
            rm -f "${data_dir}/postmaster.pid"
        fi
    fi

    # Create socket directory
    mkdir -p "${data_dir}/run"
    if [ "$EUID" -eq 0 ]; then
        chown ${POSTGRES_USER}:${POSTGRES_USER} "${data_dir}/run"
    fi

    # Start PostgreSQL
    if [ "$EUID" -eq 0 ]; then
        sudo -u ${POSTGRES_USER} /usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
            -D "${data_dir}" \
            -l "${data_dir}/postgresql.log" \
            start
    else
        /usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
            -D "${data_dir}" \
            -l "${data_dir}/postgresql.log" \
            start
    fi

    sleep 2

    # Check if started successfully
    if [ -f "${data_dir}/postmaster.pid" ]; then
        local pid=$(head -1 "${data_dir}/postmaster.pid")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PostgreSQL started successfully (PID: ${pid})${NC}"
            echo ""
            echo "Connection info:"
            echo "  Host: localhost"
            echo "  Port: ${port}"
            echo "  Socket: ${data_dir}/run"
            echo ""
            echo "Connect with:"
            echo "  psql -h localhost -p ${port} -U ${USER} postgres"
            echo ""
            echo "To initialize YCSB database:"
            echo "  $0 init-ycsb ${instance_cmd}"
            return 0
        fi
    fi

    echo -e "${RED}Failed to start PostgreSQL${NC}"
    echo "Check log: ${data_dir}/postgresql.log"
    return 1
}

# Function to stop PostgreSQL instance
stop_instance() {
    local name=$1
    local data_dir=$2

    echo -e "${YELLOW}Stopping PostgreSQL instance: ${name}${NC}"
    echo "Data Directory: ${data_dir}"
    echo ""

    if [ ! -f "${data_dir}/postmaster.pid" ]; then
        echo -e "${YELLOW}Instance is not running${NC}"
        return 0
    fi

    if [ "$EUID" -eq 0 ]; then
        sudo -u ${POSTGRES_USER} /usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
            -D "${data_dir}" \
            stop
    else
        /usr/lib/postgresql/${POSTGRES_VERSION}/bin/pg_ctl \
            -D "${data_dir}" \
            stop
    fi

    echo -e "${GREEN}✓ PostgreSQL stopped${NC}"
}

# Function to show instance status
status_instance() {
    local name=$1
    local data_dir=$2
    local port=$3

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}PostgreSQL Instance: ${name}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Data Directory: ${data_dir}"
    echo "Port: ${port}"
    echo ""

    if [ ! -f "${data_dir}/PG_VERSION" ]; then
        echo "Status: ${RED}Not initialized${NC}"
        echo ""
        echo "Initialize with: $0 init ${name}"
        return
    fi

    echo "PostgreSQL Version: $(cat ${data_dir}/PG_VERSION)"
    echo ""

    if [ -f "${data_dir}/postmaster.pid" ]; then
        local pid=$(head -1 "${data_dir}/postmaster.pid")
        if ps -p $pid > /dev/null 2>&1; then
            echo "Status: ${GREEN}Running${NC}"
            echo "PID: ${pid}"
            echo ""
            echo "Connection info:"
            echo "  psql -h localhost -p ${port} -U ${USER} postgres"
        else
            echo "Status: ${RED}Stopped (stale PID file)${NC}"
        fi
    else
        echo "Status: ${RED}Stopped${NC}"
    fi

    echo ""
    echo "Disk Usage:"
    du -sh "${data_dir}" 2>/dev/null || echo "Unable to read directory"
    echo ""
}

# Function to initialize YCSB database
init_ycsb_db() {
    local name=$1
    local data_dir=$2
    local port=$3

    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Initializing YCSB Database: ${name}${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo ""

    # Check if instance is running
    if [ ! -f "${data_dir}/postmaster.pid" ]; then
        echo -e "${RED}Error: PostgreSQL instance is not running${NC}"
        echo "Start it first: $0 start ${name}"
        return 1
    fi

    local pid=$(head -1 "${data_dir}/postmaster.pid")
    if ! ps -p $pid > /dev/null 2>&1; then
        echo -e "${RED}Error: PostgreSQL instance is not running${NC}"
        echo "Start it first: $0 start ${name}"
        return 1
    fi

    echo "Creating YCSB database and user..."
    echo ""

    # Create user and database
    if [ "$EUID" -eq 0 ]; then
        # Running as root, use postgres user
        sudo -u ${POSTGRES_USER} psql -h localhost -p ${port} -d postgres > /dev/null 2>&1 <<EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'root') THEN
        CREATE USER root WITH PASSWORD 'root';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE test OWNER root'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'test')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE test TO root;
EOF
    else
        # Running as current user
        psql -h localhost -p ${port} -d postgres > /dev/null 2>&1 <<EOF
-- Create user if not exists
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_user WHERE usename = 'root') THEN
        CREATE USER root WITH PASSWORD 'root';
    END IF;
END
\$\$;

-- Create database if not exists
SELECT 'CREATE DATABASE test OWNER root'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'test')\gexec

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE test TO root;
EOF
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ YCSB database initialized successfully${NC}"
        echo ""
        echo "Database Details:"
        echo "  Database: test"
        echo "  User: root"
        echo "  Password: root"
        echo "  Host: localhost"
        echo "  Port: ${port}"
        echo ""
        echo "Connect with:"
        echo "  psql -h localhost -p ${port} -U root -d test"
        echo ""
        echo "YCSB connection string:"
        echo "  postgresql://root:root@localhost:${port}/test"
    else
        echo -e "${RED}Failed to initialize YCSB database${NC}"
        echo "Check PostgreSQL log: ${data_dir}/postgresql.log"
        return 1
    fi
}

# Function to clean instance (remove all data)
clean_instance() {
    local name=$1
    local data_dir=$2

    echo -e "${RED}========================================${NC}"
    echo -e "${RED}WARNING: Clean Instance${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "This will DELETE all data in: ${data_dir}"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi

    # Stop if running
    if [ -f "${data_dir}/postmaster.pid" ]; then
        echo "Stopping instance first..."
        stop_instance "$name" "$data_dir"
        sleep 2
    fi

    echo "Removing data directory..."
    rm -rf "${data_dir}"
    echo -e "${GREEN}✓ Instance cleaned${NC}"
}

# Main command handler
case "${1:-}" in
    init)
        case "${2:-}" in
            sworndisk)
                init_instance "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                ;;
            cryptdisk)
                init_instance "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            *)
                echo "Usage: $0 init [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    start)
        case "${2:-}" in
            sworndisk)
                start_instance "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                ;;
            cryptdisk)
                start_instance "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            *)
                echo "Usage: $0 start [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    stop)
        case "${2:-}" in
            sworndisk)
                stop_instance "SwornDisk" "$SWORNDISK_DIR"
                ;;
            cryptdisk)
                stop_instance "CryptDisk" "$CRYPTDISK_DIR"
                ;;
            *)
                echo "Usage: $0 stop [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    restart)
        case "${2:-}" in
            sworndisk)
                stop_instance "SwornDisk" "$SWORNDISK_DIR"
                sleep 2
                start_instance "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                ;;
            cryptdisk)
                stop_instance "CryptDisk" "$CRYPTDISK_DIR"
                sleep 2
                start_instance "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            *)
                echo "Usage: $0 restart [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    status)
        case "${2:-}" in
            sworndisk)
                status_instance "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                ;;
            cryptdisk)
                status_instance "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            all|"")
                status_instance "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                status_instance "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            *)
                echo "Usage: $0 status [sworndisk|cryptdisk|all]"
                exit 1
                ;;
        esac
        ;;

    init-ycsb)
        case "${2:-}" in
            sworndisk)
                init_ycsb_db "SwornDisk" "$SWORNDISK_DIR" "$SWORNDISK_PORT"
                ;;
            cryptdisk)
                init_ycsb_db "CryptDisk" "$CRYPTDISK_DIR" "$CRYPTDISK_PORT"
                ;;
            *)
                echo "Usage: $0 init-ycsb [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    clean)
        case "${2:-}" in
            sworndisk)
                clean_instance "SwornDisk" "$SWORNDISK_DIR"
                ;;
            cryptdisk)
                clean_instance "CryptDisk" "$CRYPTDISK_DIR"
                ;;
            *)
                echo "Usage: $0 clean [sworndisk|cryptdisk]"
                exit 1
                ;;
        esac
        ;;

    *)
        echo "PostgreSQL Instance Manager"
        echo ""
        echo "Usage: $0 <command> <instance>"
        echo ""
        echo "Commands:"
        echo "  init <instance>      - Initialize a new PostgreSQL instance"
        echo "  start <instance>     - Start PostgreSQL instance"
        echo "  stop <instance>      - Stop PostgreSQL instance"
        echo "  restart <instance>   - Restart PostgreSQL instance"
        echo "  status [instance]    - Show instance status (default: all)"
        echo "  init-ycsb <instance> - Initialize YCSB database (user: root, db: test)"
        echo "  clean <instance>     - Remove instance data (WARNING: deletes all data)"
        echo ""
        echo "Instances:"
        echo "  sworndisk           - SwornDisk instance (port ${SWORNDISK_PORT})"
        echo "  cryptdisk           - CryptDisk instance (port ${CRYPTDISK_PORT})"
        echo ""
        echo "Examples:"
        echo "  $0 init sworndisk"
        echo "  $0 start sworndisk"
        echo "  $0 init-ycsb sworndisk"
        echo "  $0 status"
        echo "  $0 stop cryptdisk"
        exit 1
        ;;
esac
