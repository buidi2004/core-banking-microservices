#!/bin/bash
cd backend
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 mvn spring-boot:run &
PID=$!
sleep 15
curl -v -X POST -H "Content-Type: application/json" -d '{"phoneNumber":"0988123456","password":"password123","deviceId":"device-1"}' http://localhost:8080/api/v1/auth/register
kill $PID
