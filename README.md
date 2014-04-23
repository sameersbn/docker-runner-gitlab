# Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
	- [Data Store](#data-store)
- [Maintenance](#maintenance)
	- [SSH Login](#ssh-login)
- [Upgrading](#upgrading)

# Introduction
A CI runner for gitlab-ce.

Built on top of the [sameersbn/gitlab-ci-runner](https://github.com/sameersbn/docker-gitlab-ci-runner) base image, this repo demonstrates the use of sameersbn/gitlab-ci-runner to build a runner for your project.

Since we inherit the [sameersbn/gitlab-ci-runner](https://github.com/sameersbn/docker-gitlab-ci-runner) base image, we also inherit its runtime. This means we only have to setup the image to satisfy your projects build requirements which in this case is gitlab-ce.

All package installations are performed in the [Dockerfile](https://github.com/sameersbn/docker-runner-gitlab/master/Dockerfile) while the system configuration, such as mysql and redis setup, are performed in the [install](https://github.com/sameersbn/docker-runner-gitlab/blob/master/assets/setup/install) script.

Rest of this document describes use of the runner to perform continiuos integration of gitlab-ce.

# Installation

Pull the latest version of the image from the docker index.

```bash
docker pull sameersbn/runner-gitlab:latest
```

Alternately you can build the image yourself.

```bash
git clone https://github.com/sameersbn/docker-runner-gitlab.git
cd docker-runner-gitlab
docker build --tag="$USER/runner-gitlab" .
```

# Quick Start
For a runner to do its trick, it has to first be registered/authorized on the GitLab CI server. This can be done by running the image with the **app:setup** command.

```bash
mkdir -p /opt/gitlab-ci-runner
docker run --name runner-gitlab -i -t --rm \
	-v /opt/runner-gitlab:/home/gitlab_ci_runner/data \
  sameersbn/runner-gitlab:latest app:setup
```

The command will prompt you to specify the location of the GitLab CI server and provide the registration token to access the server. With this out of the way the image is ready, lets get is started.

```bash
docker run --name runner-gitlab -d \
	-v /opt/runner-gitlab:/home/gitlab_ci_runner/data \
	sameersbn/runner-gitlab:latest
```

You now have the runner to perform continous integration if GitLab CE.

Login to your GitLab CI server and add a CI build for gitlab-ce with the following build settings

```bash
ruby -v
gem install bundler
cp config/database.yml.mysql config/database.yml
cp config/gitlab.yml.example config/gitlab.yml
sed "s/username\:.*$/username\: runner/" -i config/database.yml
sed "s/password\:.*$/password\: 'password'/" -i config/database.yml
sed "s/gitlabhq_test/gitlabhq_test_$((RANDOM/5000))/" -i config/database.yml
touch log/application.log
touch log/test.log
bundle --without postgres
bundle exec rake db:create RAILS_ENV=test
bundle exec rake gitlab:test RAILS_ENV=test
```

# Configuration

## Data Store
GitLab CI Runner saves the configuration for connection and access to the GitLab CI server. In addition, SSH keys are generated as well. To make sure this configuration is not lost when when the container is stopped/deleted, we should mount a data store volume at

* /home/gitlab_ci_runner/data

Volumes can be mounted in docker by specifying the **'-v'** option in the docker run command.

```bash
mkdir /opt/runner-gitlab
docker run --name runner-gitlab -d -h runner-gitlab.local.host \
  -v /opt/runner-gitlab:/home/gitlab_ci_runner/data \
  sameersbn/runner-gitlab:latest
```

# Maintenance

## SSH Login
There are two methods to gain root login to the container, the first method is to add your public rsa key to the authorized_keys file and build the image.

The second method is use the dynamically generated password. Every time the container is started a random password is generated using the pwgen tool and assigned to the root user. This password can be fetched from the docker logs.

```bash
docker logs runner-gitlab 2>&1 | grep '^User: ' | tail -n1
```

This password is not persistent and changes every time the image is executed.

## Upgrading

To update the runner, simply stop the image and pull the latest version from the docker index.

```bash
docker stop runner-gitlab
docker pull sameersbn/runner-gitlab:latest
docker run --name runner-gitlab -d [OPTIONS] sameersbn/runner-gitlab:latest
```
