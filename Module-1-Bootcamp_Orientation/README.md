# Data Engineering Bootcamp - Day 0 Set Up

In this section, we will be going through the [Bootcamp Orientation](https://www.youtube.com/watch?v=9Ng5juIg7LY&t=8s), specifically the software setups needed for the course. The main ones we would be looking at are:
1. [`DOCKER + COMPOSE`](#docker-and-docker-compose)
2. `POSTGRES + PGADMIN SETUP`
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
