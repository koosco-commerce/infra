# ===============================
# Infra 관리용 Makefile
# ===============================

# -------------------------------
# Variables
# -------------------------------
# Colors
YELLOW = \033[1;33m
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m # No Color

# Kafka
KAFKA_COMPOSE = kafka/docker-compose.yaml

# Kubernetes
K8S_DIR = k8s
NAMESPACE = commerce
NAMESPACE_FILE = $(K8S_DIR)/namespace.yaml
INGRESS_FILE = $(K8S_DIR)/ingress.yaml

# Services
SERVICES = catalog-service auth-service user-service

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

# ===============================
# Kubernetes (k8s) 관리
# ===============================

# -------------------------------
# Namespace 생성
# -------------------------------
k8s-ns-create:
	kubectl apply -f $(NAMESPACE_FILE)

# -------------------------------
# Namespace 삭제
# 주의: 네임스페이스 내 모든 리소스가 삭제됩니다
# -------------------------------
k8s-ns-delete:
	@echo "⚠️  WARNING: This will delete the '$(NAMESPACE)' namespace and ALL its resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		kubectl delete namespace $(NAMESPACE); \
	else \
		echo "Cancelled."; \
	fi

# -------------------------------
# Namespace 목록 확인
# -------------------------------
k8s-ns-list:
	kubectl get namespaces

# -------------------------------
# Namespace 상세 정보
# -------------------------------
k8s-ns-info:
	kubectl describe namespace $(NAMESPACE)

# -------------------------------
# 현재 컨텍스트를 해당 네임스페이스로 설정
# -------------------------------
k8s-ns-switch:
	kubectl config set-context --current --namespace=$(NAMESPACE)

# -------------------------------
# Ingress 적용
# -------------------------------
k8s-ingress-apply:
	kubectl apply -f $(INGRESS_FILE) -n $(NAMESPACE)

# -------------------------------
# Ingress 삭제 (특정 파일)
# 예: make k8s-ingress-delete INGRESS=ingress.yaml
# -------------------------------
k8s-ingress-delete:
	@if [ -z "$(INGRESS)" ]; then \
		echo "❌ Error: INGRESS variable is required"; \
		echo "Usage: make k8s-ingress-delete INGRESS=ingress.yaml"; \
		exit 1; \
	fi
	kubectl delete -f $(K8S_DIR)/$(INGRESS) -n $(NAMESPACE)

# -------------------------------
# 모든 Ingress 삭제
# -------------------------------
k8s-ingress-delete-all:
	kubectl delete ingress --all -n $(NAMESPACE)

# -------------------------------
# Ingress 목록 확인
# -------------------------------
k8s-ingress-list:
	kubectl get ingress -n $(NAMESPACE)

# -------------------------------
# Ingress 상세 정보
# 예: make k8s-ingress-describe NAME=commerce-ingress
# -------------------------------
k8s-ingress-describe:
	@if [ -z "$(NAME)" ]; then \
		kubectl describe ingress -n $(NAMESPACE); \
	else \
		kubectl describe ingress $(NAME) -n $(NAMESPACE); \
	fi

# -------------------------------
# Ingress 상세 정보 (YAML)
# 예: make k8s-ingress-get NAME=commerce-ingress
# -------------------------------
k8s-ingress-get:
	@if [ -z "$(NAME)" ]; then \
		kubectl get ingress -n $(NAMESPACE) -o yaml; \
	else \
		kubectl get ingress $(NAME) -n $(NAMESPACE) -o yaml; \
	fi

# -------------------------------
# Kubernetes 전체 상태 확인
# -------------------------------
k8s-status:
	@echo "=== Namespace Status ==="
	kubectl get namespace $(NAMESPACE) 2>/dev/null || echo "Namespace '$(NAMESPACE)' does not exist"
	@echo ""
	@echo "=== Ingress Status ==="
	kubectl get ingress -n $(NAMESPACE) 2>/dev/null || echo "No ingresses found in namespace '$(NAMESPACE)'"
	@echo ""
	@echo "=== Services ==="
	kubectl get services -n $(NAMESPACE) 2>/dev/null || echo "No services found in namespace '$(NAMESPACE)'"
	@echo ""
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE) 2>/dev/null || echo "No pods found in namespace '$(NAMESPACE)'"

# -------------------------------
# 전체 k8s 리소스 적용
# -------------------------------
k8s-apply-all:
	kubectl apply -f $(NAMESPACE_FILE)
	kubectl apply -f $(INGRESS_FILE) -n $(NAMESPACE)

# ===============================
# Kubernetes Deployment 관리
# ===============================

# -------------------------------
# 모든 서비스 중지 (replicas=0)
# -------------------------------
k8s-stop:
	@echo "$(YELLOW)Stopping all services (scaling to 0)...$(NC)"
	@kubectl scale deployment/catalog-service -n $(NAMESPACE) --replicas=0
	@kubectl scale deployment/catalog-service-mariadb -n $(NAMESPACE) --replicas=0
	@kubectl scale deployment/auth-service -n $(NAMESPACE) --replicas=0
	@kubectl scale deployment/auth-service-mariadb -n $(NAMESPACE) --replicas=0
	@kubectl scale deployment/user-service -n $(NAMESPACE) --replicas=0
	@kubectl scale deployment/user-service-mariadb -n $(NAMESPACE) --replicas=0
	@echo "$(GREEN)✓ All services stopped (replicas=0)$(NC)"

# -------------------------------
# 모든 서비스 시작
# -------------------------------
k8s-start:
	@echo "$(YELLOW)Starting all services...$(NC)"
	@kubectl scale deployment/catalog-service-mariadb -n $(NAMESPACE) --replicas=1
	@kubectl scale deployment/catalog-service -n $(NAMESPACE) --replicas=2
	@kubectl scale deployment/auth-service-mariadb -n $(NAMESPACE) --replicas=1
	@kubectl scale deployment/auth-service -n $(NAMESPACE) --replicas=2
	@kubectl scale deployment/user-service-mariadb -n $(NAMESPACE) --replicas=1
	@kubectl scale deployment/user-service -n $(NAMESPACE) --replicas=2
	@echo "$(GREEN)✓ All services started (replicas=2)$(NC)"

# -------------------------------
# 모든 서비스 스케일 조정
# 예: make k8s-scale REPLICAS=3
# -------------------------------
k8s-scale:
	@if [ -z "$(REPLICAS)" ]; then \
		echo "$(RED)Error: REPLICAS not specified$(NC)"; \
		echo "Usage: make k8s-scale REPLICAS=3"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Scaling all services to $(REPLICAS) replicas...$(NC)"
	@kubectl scale deployment/catalog-service -n $(NAMESPACE) --replicas=$(REPLICAS)
	@kubectl scale deployment/auth-service -n $(NAMESPACE) --replicas=$(REPLICAS)
	@kubectl scale deployment/user-service -n $(NAMESPACE) --replicas=$(REPLICAS)
	@echo "$(GREEN)✓ All services scaled to $(REPLICAS) replicas$(NC)"

# -------------------------------
# 모든 서비스 재시작
# -------------------------------
k8s-restart:
	@echo "$(YELLOW)Restarting all services...$(NC)"
	@kubectl rollout restart deployment/catalog-service -n $(NAMESPACE)
	@kubectl rollout restart deployment/auth-service -n $(NAMESPACE)
	@kubectl rollout restart deployment/user-service -n $(NAMESPACE)
	@echo "$(GREEN)✓ All services restarted$(NC)"

# -------------------------------
# Deployment 상태 확인
# -------------------------------
k8s-deployments:
	@echo "$(YELLOW)=== Deployments Status ===$(NC)"
	@kubectl get deployments -n $(NAMESPACE)
	@echo ""
	@echo "$(YELLOW)=== Pods Status ===$(NC)"
	@kubectl get pods -n $(NAMESPACE)

# -------------------------------
# 특정 서비스 스케일 조정
# 예: make k8s-scale-service SERVICE=catalog-service REPLICAS=3
# -------------------------------
k8s-scale-service:
	@if [ -z "$(SERVICE)" ] || [ -z "$(REPLICAS)" ]; then \
		echo "$(RED)Error: SERVICE and REPLICAS are required$(NC)"; \
		echo "Usage: make k8s-scale-service SERVICE=catalog-service REPLICAS=3"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Scaling $(SERVICE) to $(REPLICAS) replicas...$(NC)"
	@kubectl scale deployment/$(SERVICE) -n $(NAMESPACE) --replicas=$(REPLICAS)
	@echo "$(GREEN)✓ $(SERVICE) scaled to $(REPLICAS) replicas$(NC)"

.PHONY: kafka-up kafka-down kafka-logs kafka-restart kafka-reset kafka-topics kafka-topic-create kafka-topic-delete kafka-ps \
	k8s-ns-create k8s-ns-delete k8s-ns-list k8s-ns-info k8s-ns-switch \
	k8s-ingress-apply k8s-ingress-delete k8s-ingress-delete-all \
	k8s-ingress-list k8s-ingress-describe k8s-ingress-get \
	k8s-status k8s-apply-all \
	k8s-stop k8s-start k8s-scale k8s-restart k8s-deployments k8s-scale-service
