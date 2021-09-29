# Pinot with Spark build

Repository to build Pinot with Spark integration Docker images.

The multi-stage build for the Dockerfile is adapted from
<https://github.com/apache/pinot/blob/master/docker/images/pinot/Dockerfile>.

The release image is based off
[`dsaidgovsg/spark-k8s-addons`](https://github.com/dsaidgovsg/spark-k8s-addons) and the Spark
integration contains Kubernetes integration.

## Check Dockerfile linting (`hadolint`)

```bash
hadolint --ignore DL3008 --ignore DL3059 --ignore DL4006 Dockerfile
```

Check <https://github.com/hadolint/hadolint> on how to install `hadolint`.

## Build Example

```bash
PINOT_VERSION=0.8.0
SPARK_VERSION=2.4.8
HADOOP_VERSION=2.7.3
SCALA_VERSION=2.12
JAVA_VERSION=8
PYTHON_VERSION=3.7

docker build . \
    -t pinot-spark:${PINOT_VERSION}_spark-${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}_python-${PYTHON_VERSION} \
    --build-arg PINOT_VERSION=${PINOT_VERSION} \
    --build-arg SPARK_VERSION=${SPARK_VERSION} \
    --build-arg HADOOP_VERSION=${HADOOP_VERSION} \
    --build-arg SCALA_VERSION=${SCALA_VERSION} \
    --build-arg JAVA_VERSION=${JAVA_VERSION} \
    --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
    -f Dockerfile
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## How to Apply Template for CI build

For Linux user, you can download Tera CLI v0.4 at
<https://github.com/guangie88/tera-cli/releases> and place it in `PATH`.

Otherwise, you will need `cargo`, which can be installed via [rustup](https://rustup.rs/).

Once `cargo` is installed, simply run `cargo install tera-cli --version=^0.4.0`.
