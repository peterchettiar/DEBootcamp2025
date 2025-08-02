# Data Engineering Bootcamp - Day 0 Set Up

In this section, we will be going through the [Bootcamp Orientation](https://www.youtube.com/watch?v=9Ng5juIg7LY&t=8s), specifically the software setups needed for the course. The main ones we would be looking at are:
1. [Docker and Docker Compose](#docker-and-docker-compose)
2. [PostgreSQL and PG Admin Setup](#postgressql)
3. [PostgreSQL run in Docker](#running-postgres-in-docker)
     - [Docker Compose](#docker-compose)
4. `DBEAVER` - SQL editor (other editors can be used based on your preference)
5. `PYTHON` - Version 3.11 and above

>[!TIP]
>If you decide to pursue the course using a `Virtual Machine` instead of a local development approach, then this [github gist](https://gist.github.com/peterchettiar/6e719cd2bbdb3e6aae4e6d1895670687) can provide a detailed setup of your virtual machine instance using GCP as cloud providedr, install a full anaconda distribution (this would make sure that `python` is installed into the VM), as well as installing `docker` and `docker compose`. 

## Docker and Docker Compose

Docker is a containerization software that allows us to isolate software in a similar way to virtual machines but in a much leaner way.

A Docker image is a static snapshot of a container that we can define to run our software, or in this case our data pipelines. By exporting our Docker images to Cloud providers such as Amazon Web Services or Google Cloud Platform we can run our containers there.

Docker containers are stateless: any changes done inside a container will NOT be saved when the container is killed and started again. This is an advantage because it allows us to restore any container to its initial state in a reproducible manner, but you will have to store data elsewhere if you need to do so; a common way to do so is with volumes.

Now, there are two ways we can install docker, either downloading  `Docker Desktop` from [Docker](https://www.docker.com/) or `Docker Engine` via command-line. Both ways are perfectly fine. Of course the only difference is that with Docker Desktop you have a user interface. If you're using a VM, then Docker Engine would be a preferred choice, and given that we're doing a local environment setup, we can just use `Docker Desktop`.

🍏 For macOS
> Works on macOS 10.15+ (Catalina and newer)

1. Download Docker Desktop
  - Go to: https://www.docker.com/products/docker-desktop
  - Download the Mac (Apple Silicon) or Mac (Intel Chip) version depending on your machine.

2. Install Docker
  - Open the `.dmg` file and drag Docker into `Applications`.

3. Start Docker
  - Open Docker from Applications.
  - You’ll see the whale icon in the menu bar once it’s running.

Next, let's talk about `Docker-Compose`. **Docker Compose** is a tool that lets you define and run multiple-container Docker applications using a single YAML configuration file (`docke-compose.yaml`).

> Note: This is different from `Dockerfile` which is a blueprint for building a Docker image. `Docker-Compose` on the other hand is made up of multiple services, and each service can optionally use a Dockerfile (or a pre-built image).

Since we installed `Docker Desktop`, we don't need to install `Docker Compose` seperately. You can run `docker compose version` to verify. But if you took the other approach (i.e. installing `Docker Engine` instead), then you need to install the associated binaries for docker compose. Again thses steps are prescribed in the previously mentioned [Github Gist](https://gist.github.com/peterchettiar/6e719cd2bbdb3e6aae4e6d1895670687#run-docker-compose).


## PostgresSQL

Now that we have installed `Docker`, we can proceed to spin up `postgres` server and `pgadmin` UI using docker without the need to install the `PostgreSQL` binaries or deal with system configurations. But before doing so, let's look at some terminologies to help us understand the various components that make up the database.
1. `PostgreSQL` - This is a database server that is reliable as well as the most powerful open-source database engine. It is a relational database management system (RDBMS) that lets you store, manage, and query structured data using SQL (Structured Query Language).
2. `PgAdmin` - `pgAdmin` is a free, open-source graphical user interface (GUI) tool for managing and administering PostgreSQL databases.
3. `PgCLI` - `pgcli` is a command-line interface for PostgreSQL with auto-completion and syntax highlighting, designed to make querying more efficient and user-friendly.

> Note: For PgCLI, we can just run command `pip install pgcli` on the terminal

More basic information and concepts on `Docker` and `Postgre` can be found [here](https://github.com/peterchettiar/DEngZoomCamp_2025/tree/main/Module-1-docker-terraform#docker-and-postgres).

For the `postgres` database and `pgadmin` we can define these services in a `docker-compose.yml` file. In other words, instead of pulling the images from [DockerHub](https://hub.docker.com/) and spinning up the respective containers individually, using a docker-compose file is much faster approach. After defining these services, we can simply run the command `docker compose up -d` to spin up all the various containers in just one step.

## Running Postgres in Docker

### Docker Compose

As mentioned in the previous section, we need to define our services in a `docker-compose.yml` file. Let's break down the structure of each service:

```python
  postgres:
    image: postgres:14
    restart: on-failure
    container_name: ${DOCKER_CONTAINER}
    env_file:
      - .env
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    ports:
      - "${HOST_PORT}:5432"
    volumes:
      - ./data.dump:/docker-entrypoint-initdb.d/data.dump
      - ./scripts/init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
      - postgres-data:/var/lib/ostgresql/data
```

- For the `postgres` service as well as the `pgadmin` service, you can see the following keys are defined (in the context of CLI, these would be flags):
    - `image`: We pull the PostgreSQL version 14 image from Docker Hub
    - `restart`: We specify that the container should be restarted if it exits with a non-zero exit code (i.e. if it crashes)
    - `container_name`: We then assign a specific name for the container
    - `env_file`: Load an environment file which is useful for managing configurations
    - `environment`: Define environment variables to be passed into the container
    - `ports`: Map container's port `5432` (Postgres default) to the host machines `${HOST_PORT}`
    - `volumes`: Mounts files and directories from the host into the container
  
> [!IMPORTANT]
> These `services` and their respective `keys` are defined under the top-level `key` called `services` where you define the containers your want to run and this can be limitless.
> There is another important top-level `key` that you need to specify called `volumes` and this is usually defined at the end of the docker-compose file. This is where you define named volumes that Docker creates and manage. These persist data outside the container's lifecycle.

Now that we have our docker-compose file as well as the requisite `.env` file that holds the configurations for the docker-compose file, we can now proceed to look at `init-db.sh` shell script that contains a series of commands to restore the `data.dump` file. We have to restore the `data.dump` file because it's not a plain SQL script — it's a binary archive created by `pg_dump`. You can run the command `file data.dump` to verify the file format, chances are its `data.dump: POSIX tar archive` which is a Tar format created using `pg_dump -Ft data.dump`. But since this is a custom format and not plain sql we cannot use the command `psql` but we have to use `pg_restore` instead.

Given that the `data.dump` file is mounted into volumes in the container, we can manually restore the tables by running the bash command `docker exec -it your_postgres_container pg_restore -U your_user -d your_db /path/to/data.dump` from within the bash terminal in the container. This would restore the tables from within the container. Alternatively, we can prepare the following `init-db.sh`, and since its mounted as well in the `docker-entrypoint-initdb.d` folder inside the `postgres` container it will be executed automatically when the container is spun-up:
```bash
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
```

Couple of things is happeining in the script:
- `#!/bin/bash` - `Shebang`: tells the system to run this script using the `bash` shell.
- `set -e` - Causes the script to exit immediately if any command fails. Good for safety.
- `pg_isready` - It is a PostgreSQL utility command that is used to check if a PostgreSQL server is ready to accept connections. And we are looping it using `until` (Keep checking every second if PostgreSQL is ready, and once its ready exit the loop)
- Next we execute a SQL query to count how many tables exist in the public schema, and if its zero that means the database is empty and we can proceed to restore (`-tAc` = terse output, no formatting, just the raw count):
```bash
if [ "$(psql -U $POSTGRES_USER -d $POSTGRES_DB -tAc "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public';")" = "0" ]; then
```
- Now to execute the restore command `pg_restore -v --no-owner --no-privileges -U "$POSTGRES_USER" -d "$POSTGRES_DB" /docker-entrypoint-initdb.d/data.dump`

> Note: Please be reminded to make the shell script into an executable using the command `chmod +x scripts/init-db.sh`.
