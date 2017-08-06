#!/bin/sh

scp -P 10022 hivemall/xgboost/src/main/resources/lib/linux-arm64/libxgboost4j.so ubuntu@localhost:~/
ssh -p 10022 ubuntu@localhost
