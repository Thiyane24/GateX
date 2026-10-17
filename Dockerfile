# Stage 1: build the jar
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# Stage 2: slim runtime
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# Keeps memory inside Heroku's 512 MB dyno limit
ENV JAVA_OPTS="-Xmx300m -Xss512k -XX:+UseSerialGC"

# Heroku sets PORT, application.yaml reads it
CMD ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
