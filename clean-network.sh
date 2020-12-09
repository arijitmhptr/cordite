docker-compose -p dev down
docker rm $(docker ps -a -q)
docker volume prune -f

kill -9 `sudo lsof -t -i:8080`
