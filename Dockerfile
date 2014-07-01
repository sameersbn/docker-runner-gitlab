FROM sameersbn/gitlab-ci-runner:5.0.0
MAINTAINER sameer@damagehead.com

RUN apt-get update && \
		apt-get install -y build-essential checkinstall \
			libmysqlclient-dev zlib1g-dev libyaml-dev libssl-dev \
			libgdbm-dev libreadline-dev libncurses5-dev libffi-dev \
			libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev \
			mysql-server mysql-client redis-server fontconfig && \
		apt-get clean # 20140422

ADD assets/ /app/
RUN chmod 755 /app/setup/install
RUN /app/setup/install
