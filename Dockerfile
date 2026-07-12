FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd -r petclinic && \
    useradd -r -g petclinic petclinic
COPY target/*.jar app.jar
RUN chown -R petclinic:petclinic /app
USER petclinic
EXPOSE 8080
ENTRYPOINT ["java", "-Dspring.profiles.active=mysql", "-jar", "/app/app.jar"]
