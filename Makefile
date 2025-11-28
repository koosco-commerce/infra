# ===============================
# Kafka (infra/kafka) 관리용 Makefile
# ===============================

# Kafka compose 파일 경로
KAFKA_COMPOSE = kafka/docker-compose.yaml

# -------------------------------
# Kafka 컨테이너 실행
# -------------------------------
kafka-up:
	docker compose -f $(KAFKA_COMPOSE) up -d

# -------------------------------
# Kafka 컨테이너 중지
# -------------------------------
kafka-down:
	docker compose -f $(KAFKA_COMPOSE) down

# -------------------------------
# Kafka 로그 확인
# -------------------------------
kafka-logs:
	docker compose -f $(KAFKA_COMPOSE) logs -f

# -------------------------------
# Kafka 컨테이너 재시작
# -------------------------------
kafka-restart:
	docker compose -f $(KAFKA_COMPOSE) down
	docker compose -f $(KAFKA_COMPOSE) up -d

# -------------------------------
# Kafka 데이터 삭제(클린 상태 시작)
# -------------------------------
kafka-reset:
	docker compose -f $(KAFKA_COMPOSE) down
	sudo rm -rf kafka/kafka_data
	mkdir -p kafka/kafka_data
	docker compose -f $(KAFKA_COMPOSE) up -d

# -------------------------------
# Kafka 토픽 목록 확인
# -------------------------------
kafka-topics:
	docker exec -it kafka-kraft \
		bash -c "/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092"

# -------------------------------
# Kafka 토픽 생성
# 예: make kafka-topic-create TOPIC=test-topic
# -------------------------------
kafka-topic-create:
	docker exec -it kafka-kraft \
		bash -c "/opt/kafka/bin/kafka-topics.sh --create --topic $(TOPIC) --bootstrap-server localhost:9092"

# -------------------------------
# Kafka 토픽 삭제
# 예: make kafka-topic-delete TOPIC=test-topic
# -------------------------------
kafka-topic-delete:
	docker exec -it kafka-kraft \
		bash -c "/opt/kafka/bin/kafka-topics.sh --delete --topic $(TOPIC) --bootstrap-server localhost:9092"

# -------------------------------
# Kafka 컨테이너 상태
# -------------------------------
kafka-ps:
	docker compose -f $(KAFKA_COMPOSE) ps

.PHONY: kafka-up kafka-down kafka-logs kafka-restart kafka-reset kafka-topics kafka-topic-create kafka-topic-delete kafka-ps
