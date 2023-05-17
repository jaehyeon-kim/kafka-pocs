## maven

wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz \
  && tar xvf apache-maven-3.8.8-bin.tar.gz \
  && sudo mv apache-maven-3.8.8 /opt/maven \
  && rm apache-maven-3.8.8-bin.tar.gz

export PATH="/opt/maven/bin:$PATH"

## build
echo "building glue schema registry..."
cd plugins/$SOURCE_NAME/build-tools \
  && mvn clean install -DskipTests -Dcheckstyle.skip -Dmaven.javadoc.skip=true \
  && cd .. \
  && mvn clean install -DskipTests -Dmaven.javadoc.skip=true -Dmaven.javadoc.skip=true \
  && mvn dependency:copy-dependencies
