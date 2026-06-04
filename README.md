# docker-rover

**Initial Stuff to Run**
```
cat <<'EOF' >> ~/.bashrc

# Allow Docker containers to access X11 (only when X is available)
if [ -n "$DISPLAY" ] && command -v xhost >/dev/null 2>&1; then
    xhost +local:docker >/dev/null 2>&1
fi
EOF
```
**Building & Running Docker**

Navigate to _terraformers-ws/docker_ and run:
```
docker compose up --build
```
You only need to build if there is a change to the docker files! After this you **DO NOT** need to include the __--build__ when starting up the docker.
To enter the docker on another terminal:
```
docker exec -ti terraformers-container bash
```
This will allow you to enter the docker and utilize everything inside.
