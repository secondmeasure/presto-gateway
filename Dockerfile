FROM openjdk:11.0.2-jre-slim

ARG NAME=gateway-ha
ARG NAMESPACE=presto-gateway
ARG VERSION=1.9.0

LABEL name="${NAME}" \
        namespace="${NAMESPACE}" \
        version="${VERSION}"

RUN apt-get update && apt-get install -y curl

ARG USER=presto-gateway
ARG UID=1501
ARG GROUP=presto-gateway
ARG GID=1501

ARG MAVEN_VERSION=3.8.5

USER root

RUN groupadd ${GROUP} --gid ${GID} \
        && useradd ${USER} --uid ${UID} --gid ${GID} \
        && mkdir -p /usr/lib/presto-gateway/bin /usr/lib/presto-gateway/conf

ARG USER_HOME_DIR="/root"

# Download maven and install and correct location
ARG BASE_URL=https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

# Build project
WORKDIR /app
COPY . .
RUN mvn clean install

# Copy jar and conf to suitable location
RUN cp gateway-ha/target/gateway-ha-${VERSION}-SNAPSHOT-jar-with-dependencies.jar /usr/lib/presto-gateway/bin/gateway-ha-${VERSION}-SNAPSHOT-jar-with-dependencies.jar
RUN chmod +x /usr/lib/presto-gateway/bin/gateway-ha-${VERSION}-SNAPSHOT-jar-with-dependencies.jar
COPY gateway-ha/gateway-ha-config.yml /usr/lib/presto-gateway/conf/gateway-ha-config.yml

USER 1501:1501
CMD java -jar /usr/lib/presto-gateway/bin/gateway-ha-${VERSION}-SNAPSHOT-jar-with-dependencies.jar server /usr/lib/presto-gateway/conf/gateway-ha-config.yml
