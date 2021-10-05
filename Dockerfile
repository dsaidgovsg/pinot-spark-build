# This file is adapted from
# https://github.com/apache/pinot/blob/master/docker/images/pinot/Dockerfile
ARG PINOT_VERSION
ARG JAVA_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG PYTHON_VERSION
FROM maven:3.8-openjdk-11-slim AS pinot_build_env

ARG PINOT_VERSION
ARG JAVA_VERSION
ARG SCALA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION

SHELL ["/bin/bash", "-c"]

ENV PINOT_HOME=/opt/pinot

RUN set -euo pipefail && \
    apt-get update; \
    apt-get install -y --no-install-recommends git; \
    rm -rf /var/lib/apt/lists/*; \
    :

RUN git clone https://github.com/apache/pinot.git -b "release-${PINOT_VERSION}" --depth 1 /opt/pinot-build

RUN set -euo pipefail && \
    pushd /opt/pinot-build; \
    SCALA_LATEST_PATCH_VERSION="$(curl -s https://www.scala-lang.org/download/all.html | grep -oP "/download/${SCALA_VERSION}.\d+" | grep -o "${SCALA_VERSION}.*" | sort -Vr | head -n1)"; \
    CPU_CORES="$(grep -c processor /proc/cpuinfo)"; \
    # This repo has "javac: invalid target release: 8u302" issue before, so good idea to print out the version
    javac -version; \
    # We do not want to build v0_deprecated because those modules cause compile error
    mvn install package -DskipTests -Pbin-dist -Pbuild-shaded-jar \
        -pl -pinot-plugins/pinot-batch-ingestion/v0_deprecated/pinot-ingestion-common,-pinot-plugins/pinot-batch-ingestion/v0_deprecated/pinot-hadoop,-pinot-plugins/pinot-batch-ingestion/v0_deprecated/pinot-spark \
        -T "${CPU_CORES}" \
        -Djdk.version="${JAVA_VERSION}" \
        -Dscala.version="${SCALA_LATEST_PATCH_VERSION}" \
        -Dscala.binary.version="${SCALA_VERSION}" \
        -Dspark.version="${SPARK_VERSION}" \
        -Dhadoop.version="${HADOOP_VERSION}"; \
    mkdir -p ${PINOT_HOME}/configs; \
    mkdir -p ${PINOT_HOME}/data; \
    cp -r pinot-distribution/target/apache-pinot-*-bin/apache-pinot-*-bin/* ${PINOT_HOME}/.; \
    chmod +x ${PINOT_HOME}/bin/*.sh; \
    popd; \
    :

FROM dsaidgovsg/spark-k8s-addons:v5_${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}_python-${PYTHON_VERSION}

ENV PINOT_HOME=/opt/pinot
ENV PINOT_VERSION="${PINOT_VERSION}"

# pinot assumes root user
USER root

COPY --from=pinot_build_env ${PINOT_HOME} ${PINOT_HOME}
COPY --from=pinot_build_env /opt/pinot-build/docker/images/pinot/bin ${PINOT_HOME}/bin
COPY --from=pinot_build_env /opt/pinot-build/docker/images/pinot/etc ${PINOT_HOME}/etc
COPY --from=pinot_build_env /opt/pinot-build/docker/images/pinot/examples ${PINOT_HOME}/examples

# expose ports for controller/broker/server/admin
EXPOSE 9000 8099 8098 8097 8096

WORKDIR ${PINOT_HOME}
ENTRYPOINT ["./bin/pinot-admin.sh"]

CMD ["run"]
