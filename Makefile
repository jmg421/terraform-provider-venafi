#Plugin information
PLUGIN_NAME := terraform-provider-venafi
PLUGIN_DIR := bin
PLUGIN_PATH := $(PLUGIN_DIR)/$(PLUGIN_NAME)

TEST?=$$(go list ./... |grep -v 'vendor')
GOFMT_FILES?=$$(find . -name '*.go' |grep -v vendor)

all: build test testacc


#Build
build:
	env GOOS=linux   GOARCH=amd64 go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-linux || exit 1
	env GOOS=linux   GOARCH=386   go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-linux86 || exit 1
	env GOOS=darwin  GOARCH=amd64 go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-darwin || exit 1
	env GOOS=darwin  GOARCH=386   go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-darwin86 || exit 1
	env GOOS=windows GOARCH=amd64 go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-windows || exit 1
	env GOOS=windows GOARCH=386   go build -ldflags '-s -w' -o $(PLUGIN_DIR)/$(PLUGIN_NAME)-windows86 || exit 1
	chmod +x $(PLUGIN_DIR)/*

dev: clean fmtcheck
	go test ./...
	go build
	terraform init

clean:
	rm -fv terraform.tfstate*
	rm -fv $(PLUGIN_NAME)

test: fmtcheck
	go test -i $(TEST) || exit 1
	echo $(TEST) | \
		xargs -t -n4 go test $(TESTARGS) -timeout=30s -parallel=4
testacc: fmtcheck
	TF_ACC=1 go test $(TEST) -v $(TESTARGS) -timeout 120m

fmt:
	gofmt -w $(GOFMT_FILES)

fmtcheck:
	@sh -c "'$(CURDIR)/scripts/gofmtcheck.sh'"

#Integration tests using real terrafomr binary
test_e2e: test_e2e_dev test_e2e_tpp test_e2e_cloud

test_e2e_tpp:
	echo yes|terraform apply -target=venafi_certificate.tpp_certificate
	terraform state show venafi_certificate.tpp_certificate
	terraform output cert_certificate_tpp > /tmp/cert_certificate_tpp.pem
	cat /tmp/cert_certificate_tpp.pem
	cat /tmp/cert_certificate_tpp.pem|openssl x509 -inform pem -noout -issuer -serial -subject -dates

test_e2e_cloud:
	echo yes|terraform apply -target=venafi_certificate.cloud_certificate
	terraform state show venafi_certificate.cloud_certificate
	terraform output cert_certificate_cloud > /tmp/cert_certificate_cloud.pem
	cat /tmp/cert_certificate_cloud.pem
	cat /tmp/cert_certificate_cloud.pem|openssl x509 -inform pem -noout -issuer -serial -subject -dates

test_e2e_dev:
	echo yes|terraform apply -target=venafi_certificate.dev_certificate
	terraform state show venafi_certificate.dev_certificate
	terraform output cert_certificate_dev > /tmp/cert_certificate_dev.pem
	cat /tmp/cert_certificate_dev.pem
	cat /tmp/cert_certificate_dev.pem|openssl x509 -inform pem -noout -issuer -serial -subject -dates
	terraform output cert_private_key_dev > /tmp/cert_private_key_dev.pem
	cat /tmp/cert_private_key_dev.pem

test_e2e_dev_ecdsa:
	echo yes|terraform apply -target=venafi_certificate.dev_certificate_ecdsa
	terraform state show venafi_certificate.dev_certificate_ecdsa
	terraform output cert_certificate_dev_ecdsa > /tmp/cert_certificate_dev_ecdsa.pem
	cat /tmp/cert_certificate_dev_ecdsa.pem
	cat /tmp/cert_certificate_dev_ecdsa.pem|openssl x509 -inform pem -noout -issuer -serial -subject -dates
	terraform output cert_private_key_dev_ecdsa > /tmp/cert_private_key_dev_ecdsa.pem
	cat /tmp/cert_private_key_dev_ecdsa.pem