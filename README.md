

## Application Setup

Access the webui at `<your-ip>:8686`, for more information check out [Lidarr](https://github.com/lidarr/Lidarr).

Special Note: Following our current folder structure will result in an inability to hardlink from your downloads to your Music folder because they are on separate volumes. To support hardlinking, simply ensure that the Music and downloads data are on a single volume. For example, if you have /mnt/storage/Music and /mnt/storage/downloads/completed/Music, you would want something like /mnt/storage:/media for your volume. Then you can hardlink from /media/downloads/completed to /media/Music.

Another item to keep in mind, is that within Lidarr itself, you should then map your download client folder to your Lidarr folder: Settings -> Download Client -> advanced -> remote path mappings. I input the host of my download client (matches the download client defined) remote path is /downloads/Music (relative to the internal container path) and local path is /media/downloads/completed/Music, assuming you have folders to separate your downloaded data types.

### Media folders

We have set `/music` and `/downloads` as ***optional paths***, this is because it is the easiest way to get started. While easy to use, it has some drawbacks. Mainly losing the ability to hardlink (TL;DR a way for a file to exist in multiple places on the same file system while only consuming one file worth of space), or atomic move (TL;DR instant file moves, rather than copy+delete) files while processing content.

Use the optional paths if you don't understand, or don't want hardlinks/atomic moves.

The folks over at servarr.com wrote a good [write-up](https://wiki.servarr.com/docker-guide#consistent-and-well-planned-paths) on how to get started with this.

## Read-Only Operation

This image can be run with a read-only container filesystem. For details please [read the docs](https://docs.linuxserver.io/misc/read-only/).


## Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

### docker-compose (recommended, [click here for more info](https://docs.linuxserver.io/general/docker-compose))

```yaml
---
services:
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest
    container_name: lidarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/lidarr/config:/config
      - /path/to/music:/music #optional
      - /path/to/downloads:/downloads #optional
    ports:
      - 8686:8686
    restart: unless-stopped
```

### docker cli ([click here for more info](https://docs.docker.com/engine/reference/commandline/cli/))

```bash
docker run -d \
  --name=lidarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -p 8686:8686 \
  -v /path/to/lidarr/config:/config \
  -v /path/to/music:/music `#optional` \
  -v /path/to/downloads:/downloads `#optional` \
  --restart unless-stopped \
  lscr.io/linuxserver/lidarr:latest
```

## Parameters

Containers are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 8686` | Application WebUI |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Etc/UTC` | specify a timezone to use, see this [list](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List). |
| `-v /config` | Configuration files for Lidarr. |
| `-v /music` | Music files (See note in Application setup). |
| `-v /downloads` | Path to your download folder for music (See note in Application setup). |
| `--read-only=true` | Run container with a read-only filesystem. Please [read the docs](https://docs.linuxserver.io/misc/read-only/). |

## Environment variables from files (Docker secrets)

You can set any environment variable from a file by using a special prepend `FILE__`.

As an example:

```bash
-e FILE__MYVAR=/run/secrets/mysecretvariable
```

Will set the environment variable `MYVAR` based on the contents of the `/run/secrets/mysecretvariable` file.

## Umask for running applications

For all of our images we provide the ability to override the default umask settings for services started within the containers using the optional `-e UMASK=022` setting.
Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add. Please read up [here](https://en.wikipedia.org/wiki/Umask) before asking for support.

## User / Group Identifiers

When using volumes (`-v` flags), permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id your_user` as below:

```bash
id your_user
```

Example output:

```text
uid=1000(your_user) gid=1000(your_user) groups=1000(your_user)
```

## Docker Mods

[![Docker Mods](https://img.shields.io/badge/dynamic/yaml?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=lidarr&query=%24.mods%5B%27lidarr%27%5D.mod_count&url=https%3A%2F%2Fraw.githubusercontent.com%2Flinuxserver%2Fdocker-mods%2Fmaster%2Fmod-list.yml)](https://mods.linuxserver.io/?mod=lidarr "view available mods for this container.") [![Docker Universal Mods](https://img.shields.io/badge/dynamic/yaml?color=94398d&labelColor=555555&logoColor=ffffff&style=for-the-badge&label=universal&query=%24.mods%5B%27universal%27%5D.mod_count&url=https%3A%2F%2Fraw.githubusercontent.com%2Flinuxserver%2Fdocker-mods%2Fmaster%2Fmod-list.yml)](https://mods.linuxserver.io/?mod=universal "view available universal mods.")

We publish various [Docker Mods](https://github.com/linuxserver/docker-mods) to enable additional functionality within the containers. The list of Mods available for this image (if any) as well as universal mods that can be applied to any one of our images can be accessed via the dynamic badges above.

## Support Info

* Shell access whilst the container is running:

    ```bash
    docker exec -it lidarr /bin/bash
    ```

* To monitor the logs of the container in realtime:

    ```bash
    docker logs -f lidarr
    ```

* Container version number:

    ```bash
    docker inspect -f '{{ index .Config.Labels "build_version" }}' lidarr
    ```

* Image version number:

    ```bash
    docker inspect -f '{{ index .Config.Labels "build_version" }}' lscr.io/linuxserver/lidarr:latest
    ```

## Updating Info

Most of our images are static, versioned, and require an image update and container recreation to update the app inside. With some exceptions (noted in the relevant readme.md), we do not recommend or support updating apps inside the container. Please consult the [Application Setup](#application-setup) section above to see if it is recommended for the image.

Below are the instructions for updating containers:

### Via Docker Compose

* Update images:
    * All images:

        ```bash
        docker-compose pull
        ```

    * Single image:

        ```bash
        docker-compose pull lidarr
        ```

* Update containers:
    * All containers:

        ```bash
        docker-compose up -d
        ```

    * Single container:

        ```bash
        docker-compose up -d lidarr
        ```

* You can also remove the old dangling images:

    ```bash
    docker image prune
    ```

### Via Docker Run

* Update the image:

    ```bash
    docker pull lscr.io/linuxserver/lidarr:latest
    ```

* Stop the running container:

    ```bash
    docker stop lidarr
    ```

* Delete the container:

    ```bash
    docker rm lidarr
    ```

* Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* You can also remove the old dangling images:

    ```bash
    docker image prune
    ```

### Image Update Notifications - Diun (Docker Image Update Notifier)

**tip**: We recommend [Diun](https://crazymax.dev/diun/) for update notifications. Other tools that automatically update containers unattended are not recommended or supported.

## Building locally

If you want to make local modifications to these images for development purposes or just to customize the logic:

```bash
git clone https://github.com/linuxserver/docker-lidarr.git
cd docker-lidarr
docker build \
  --no-cache \
  --pull \
  -t lscr.io/linuxserver/lidarr:latest .
```

The ARM variants can be built on x86_64 hardware using `multiarch/qemu-user-static`

```bash
docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Once registered you can define the dockerfile to use with `-f Dockerfile.aarch64`.

## Versions

* **31.05.24:** - Rebase Alpine 3.20.
* **20.03.24:** - Rebase Alpine 3.19.
* **06.06.23:** - Rebase master to Alpine 3.18, deprecate armhf as per [https://www.linuxserver.io/armhf](https://www.linuxserver.io/armhf).
* **17.01.23:** - Rebase master branch to Alpine 3.17, migrate to s6v3.
* **06.06.22:** - Rebase master branch to Alpine 3.15.
* **06.05.22:** - Rebase master branch to Focal.
* **06.05.22:** - Rebase develop branch to Alpine.
* **04.02.22:** - Rebase nightly branch to Alpine, deprecate nightly-alpine branch.
* **30.12.21:** - Add nightly-alpine branch.
* **01.08.21:** - Add libchromaprint-tools.
* **11.07.21:** - Make the paths clearer to the user.
* **18.04.21:** - Switch `latest` tag to net core.
* **25.01.21:** - Publish `develop` tag.
* **20.01.21:** - Deprecate `UMASK_SET` in favor of UMASK in baseimage, see above for more information.
* **18.04.20:** - Removed /downloads and /music volumes from Dockerfiles.
* **05.04.20:** - Move app to /app.
* **01.08.19:** - Rebase to Linuxserver LTS mono version.
* **13.06.19:** - Add env variable for setting umask.
* **23.03.19:** - Switching to new Base images, shift to arm32v7 tag.
* **08.03.19:** - Rebase to Bionic, use proposed endpoint for libchromaprint.
* **26.01.19:** - Add pipeline logic and multi arch.
* **22.04.18:** - Switch to beta builds.
* **17.03.18:** - Add ENV XDG_CONFIG_HOME="/config/xdg" to Dockerfile for signalr fix.
* **27.02.18:** - Use json to query for new version.
* **23.02.18:** - Initial Release.
