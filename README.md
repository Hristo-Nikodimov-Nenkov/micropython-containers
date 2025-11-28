# MicroPython containers
Automated CI/CD workflow to generate and publish build-ready containers to DockerHub.

## Structure
Each directory is linked to DockerHub repo with the same name. All containers are built and pushed using GitHub actions workflow.

### Dockerfile
Each directory has the Dockerfile used to create the container.

### build_firmware.sh
The ENTRYPOINT of the container. Every container has one baked-in. If file with same name is present in the root directory of the project it is used insted.

### build.sh
The script is used to run "docker build ..." for the specific directory.

### versions.json
Used as input for versions and tags.

### README.md
Documentation for specific container set.