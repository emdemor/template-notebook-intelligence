IMAGE  := notebook-intelligence
CONTAINER := notebook-intelligence
PORT   := 8888
WORK_DIR := $(PWD)

.PHONY: build run stop logs clean

build:
	docker build -f docker/Docerkfile -t $(IMAGE) .

run:
	docker run -d \
		--name $(CONTAINER) \
		-p $(PORT):8888 \
		-v $(WORK_DIR):/workspace \
		-w /workspace \
		$(IMAGE)
	@echo "JupyterLab disponível em http://localhost:$(PORT)"

stop:
	docker stop $(CONTAINER)
	docker rm $(CONTAINER)

logs:
	docker logs -f $(CONTAINER)

clean: stop
	docker rmi $(IMAGE)
