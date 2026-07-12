# 1단계: 빌드 환경 (Maven 이미지 사용)
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# 2단계: 실행 환경 (기존에 작성하신 환경)
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN groupadd -r petclinic && \
    useradd -r -g petclinic petclinic

# 호스트가 아니라 1단계(builder) 컨테이너의 target에서 jar를 복사해옵니다.
COPY --from=builder /build/target/*.jar app.jar

RUN chown -R petclinic:petclinic /app
USER petclinic
CMD ["java", "-jar", "app.jar"]
