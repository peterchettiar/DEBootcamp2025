# Data Engineering Bootcamp - Day 0 Set Up

In this section, we will be going through the [Bootcamp Orientation](https://www.youtube.com/watch?v=9Ng5juIg7LY&t=8s), specifically the software setups needed for the course. The main ones we would be looking at are:
1. [`DOCKER + COMPOSE`](#docker-and-docker-compose)
2. [`POSTGRES + PGADMIN SETUP`](#postgressql)
3. `POSTGRES RUN IN DOCKER`
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

> Note: This is different for `Dockerfile` which is a blueprint for building a Docker image. 

Since we installed `Docker Desktop`, we don't need to install `Docker Compose` seperately. You can run `docker compose version` to verify. But if you took the other approach (i.e. installing `Docker Engine` instead), then you need to install the associated binaries for docker compose. Again thses steps are prescribed in the previously mentioned [Github Gist](https://gist.github.com/peterchettiar/6e719cd2bbdb3e6aae4e6d1895670687#run-docker-compose).


## PostgresSQL

Now that we have installed `Docker`, we can proceed to spin up `postgres` server and `pgadmin` UI using docker without the need to install the `PostgreSQL` binaries or deal with system configurations. But before doing so, let's look at some terminologies to help us understand the various components that make up the database.
1. `PostgreSQL` - This is a database server that is reliable as well as the most powerful open-source database engine. It is a relational database management system (RDBMS) that lets you store, manage, and query structured data using SQL (Structured Query Language).
2. `PgAdmin` - `pgAdmin` is a free, open-source graphical user interface (GUI) tool for managing and administering PostgreSQL databases.
3. `PgCLI` - `pgcli` is a command-line interface for PostgreSQL with auto-completion and syntax highlighting, designed to make querying more efficient and user-friendly.

More basic information and concepts on `Docker` and `Postgre` can be found [here](https://github.com/peterchettiar/DEngZoomCamp_2025/tree/main/Module-1-docker-terraform#docker-and-postgres).

For the `postgres` database and `pgadmin` we can define these services in a `docker-compose.yml` file. In other words, instead of downloading the images and spinning up 
