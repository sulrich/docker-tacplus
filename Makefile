TACPLUS_VERSION?=202109260929
TACPLUS_HASH?=7b6b741ba5ddba01e27cb83a36dfb8c74d61e18b4121584cf2302d0dc186f274

.PHONY: ubuntu

all: ubuntu

ubuntu:
	docker build -t tac_plus:ubuntu                    \
		--build-arg TACPLUS_VERSION=$(TACPLUS_VERSION) \
		--build-arg TACPLUS_HASH=$(TACPLUS_HASH)       \
		-f Dockerfile .
