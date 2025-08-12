# Immich Self-Hosted Photo and Video Backup

![Immich Logo](https://immich.app/img/logo.svg)

This repository contains the necessary files to run a self-hosted instance of [Immich](https://github.com/immich-app/immich), a high-performance, self-hosted photo and video management solution.

> **Warning**: Immich is under very active development. Expect bugs and breaking changes. It is not recommended to use it as the only copy of your photos and videos. Always have a backup.

## About This Repository

This repository provides a convenient, ready-to-use setup for deploying a self-hosted Immich instance using Docker. It is intended for users who want a simple way to get started with Immich without having to manually configure the entire environment.

### Key Changes and Additions

- **Simplified Setup:** This repository includes a pre-configured `docker-compose.yml` file and an `.env.template` to make the initial setup as straightforward as possible.
- **Helper Scripts:** A collection of shell scripts (`start.sh`, `stop.sh`, `restart.sh`, `update.sh`, `logs.sh`, `immich-go.sh`) are included to simplify common management tasks.
- **Self-Contained:** All necessary files to run the application are included in this repository, making it easy to clone and deploy.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Configure Your Environment](#2-configure-your-environment)
  - [3. Start the Services](#3-start-the-services)
- [Usage](#usage)
  - [Web Interface](#web-interface)
  - [Mobile App](#mobile-app)
- [Configuration](#configuration)
- [Updating Your Instance](#updating-your-instance)
- [Helper Scripts](#helper-scripts)
- [Project Reference](#project-reference)

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/) (usually included with Docker Desktop)
- `git` for cloning the repository.

## Getting Started

Follow these steps to get your Immich instance up and running.

### 1. Clone the Repository

If you haven't already, clone this repository to your local machine:

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure Your Environment

The configuration for your Immich instance is managed through a `.env` file. A template is provided as `.env.template`.

1.  **Create your `.env` file:**
    ```bash
    cp .env.template .env
    ```

2.  **Edit the `.env` file:**
    Open the `.env` file in a text editor. At a minimum, you should set a strong, unique password for the PostgreSQL database:

    ```dotenv
    # .env

    # Change this to a long, random, and secure password.
    DB_PASSWORD=your-super-secret-password
    ```

    It is also highly recommended to change other secrets like `JWT_SECRET`. You can generate a random string for this.

### 3. Start the Services

Once your `.env` file is configured, you can start all the Immich services in detached mode:

```bash
docker compose up -d
```

The first time you run this, Docker will download all the necessary container images. This might take a few minutes depending on your internet connection.

After the services have started, you can check their status with:

```bash
docker compose ps
```

## Usage

### Web Interface

Once the services are running, you can access the Immich web interface by navigating to:

`http://<your-server-ip>:2283`

Replace `<your-server-ip>` with the IP address of the machine running Docker. If you are running it on your local machine, you can use `http://localhost:2283`.

The first time you access the application, you will be prompted to create an administrator account.

### Mobile App

Immich has companion mobile apps for Android and iOS that can automatically back up photos and videos from your phone. Download them from the official app stores and connect to your self-hosted server by entering your server URL (`http://<your-server-ip>:2283`).

## Configuration

All configuration is done via the `.env` file. Refer to the comments in `.env.template` for a description of each variable. For more advanced configuration options, please refer to the official Immich documentation.

## Performance Tuning

For a smoother user experience, this `docker-compose.yml` is configured to optimize performance by separating background tasks from the main application server and prioritizing CPU resources.

### Dedicated Job Containers

-   **`immich-microservice`**: This container is dedicated to running background jobs like video transcoding and other processing tasks. By separating these tasks, the main `immich-server` can remain responsive to user requests.
-   **`machine-learning`**: This container handles all machine learning tasks, such as image recognition and classification. Isolating this resource-intensive process prevents it from impacting the performance of the core application.

### CPU Prioritization

The `cpu_shares` option is used in the `docker-compose.yml` to allocate CPU resources:

-   **`immich-server` (`cpu_shares: 2048`)**: The main server is given the highest priority to ensure the web interface and API are always fast and responsive.
-   **`immich-microservice` (`cpu_shares: 1024`)**: The background jobs container has a lower priority than the main server.
-   **`machine-learning` (`cpu_shares: 512`)**: The machine learning container has the lowest priority, ensuring that it only uses significant CPU resources when the system is not busy with other tasks.

This configuration ensures that background processing and machine learning tasks do not slow down the user-facing parts of the application.

## Updating Your Instance

To update your Immich instance to the latest version, you can use the included `update.sh` script or follow these manual steps:

1.  **Pull the latest changes from the repository:**
    ```bash
    git pull
    ```

2.  **Pull the latest container images:**
    ```bash
    docker compose pull
    ```

3.  **Restart the services with the new images:**
    ```bash
    docker compose up -d --remove-orphans
    ```

## Helper Scripts

This repository includes several shell scripts to simplify common tasks:

-   `start.sh`: Starts all Immich services.
-   `stop.sh`: Stops all Immich services.
-   `restart.sh`: Restarts all Immich services.
-   `update.sh`: Pulls the latest container images and restarts the services.
-   `logs.sh`: Tails the logs for all running services.
-   `immich-go.sh`: A wrapper to run the `immich-go` tool for bulk uploading.

## Project Reference

This setup uses the official Immich project. For more detailed information, feature requests, and to report issues, please refer to the main project repository and documentation.

-   **Official Immich GitHub Repository:** [https://github.com/immich-app/immich](https://github.com/immich-app/immich)
-   **Official Immich Documentation:** [https://immich.app/](https://immich.app/)

---
*This README was generated to provide a clear and concise guide for this specific self-hosted setup.*
