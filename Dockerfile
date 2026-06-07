FROM eclipse-temurin:17-jdk
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]

FROM myjenkins-blueocean:2.555.2-1
USER root
RUN groupadd -g 120 docker && usermod -aG docker jenkins
RUN apt-get update && apt-get install -y git
USER jenkins
