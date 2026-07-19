# 1단계: 빌드 환경 구성
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 2단계: 실행 환경 구성
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd -r petclinic && useradd -r -g petclinic petclinic
COPY --from=builder /build/target/*.jar app.jar
RUN chown -R petclinic:petclinic /app
USER petclinic
CMD ["java", "-jar", "app.jar"]
