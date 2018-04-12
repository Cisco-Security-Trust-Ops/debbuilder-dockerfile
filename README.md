# Purpose

The intent is to distribute a base container for developing, building, and regressing debian packages.  Due to lowering security to allow the architecture to work properly, this container is not meant to run as a service container for application deployment.  

# Design Decisions

1. Allow user to mount their workspace - With docker, the ability to pass in -u to specify the user/group works well in most scenerios.  The dpkg-buildpackage tool, however, requires the arbitrary UIDs to have a username as well as sudoers access for that user.  See http://blog.dscpl.com.au/2015/12/random-user-ids-when-running-docker.html for details of this scenerio.  We used NSS Wrapper for this to allow the uid to be assigned the username rpmbuilder at runtime.

2. Allow sudoers access for testing install in container - NSS Wrapper does not play nicely with sudo due to LD_PRELOAD and other environment variables needed by NSS Wrapper to properly work.  The sudoers file was modified to allow LD_PRELOAD and other environmental variables that are important for sudo to work.

# How to use this image

An example git layout is below:

```git
.git
debian
   rules
   patches
```

## Start an instance

```console
$ docker run -it -u `id -u`:`id -g` -v `pwd`:/debbuilder ciscosecuritytrustops/debbuilder:<tag> /bin/bash
```

... where `tag` is the version of the container.  The host volume must be mounted to /debbuilder in the container as this is the home directory of the debbuilder user.

## Start an instance with signing

```console
$ docker run -i --rm -u `id -u`:`id -g` -e 'GPG_KEY_FILE=/run/GPG-KEY.key' -e 'GPG_KEY_ID=89A86901' -e 'GPG_PASSPHRASE=passphrase' -v `pwd`/mykey.key:/run/GPG-KEY.key -v ${WORKSPACE}:/debbuilder ciscosecuritytrustops/debbuilder:<tag> /bin/bash
```

## Using a custom Dockerfile

It may be that a missing package may be needed that is not available in the base image.  An example below shows how you can build a customer Docker image using ciscosecuritytrustops/debbuilder as the base image.

```console
FROM ciscosecuritytrustops/debbuilder:ubuntu16-1

sudo apt-get update && apt-get install -y myspecial_package
```

## Environment Variables

When you start the image, you can adjust some configuration passing one or more environment variables on the `docker run` command line.

### `GPG_KEY`

(Optional) The GPG key for signing.

### `GPG_ID`

(Optional unless GPG_KEY specified) The GPG key ID.

### `GPG_PASSPHRASE`

(Optional) The passphrase for signing.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load keys and passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run --name some-mysql -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql-root -d %%IMAGE%%:tag
```

Currently, this is only supported for `GPG_KEY`.


# Caveats
