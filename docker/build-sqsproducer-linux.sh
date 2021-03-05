DOCKER_IMAGE_NAME=swift:5.3.3-amazonlinux2
WORKSPACE="$(pwd)/.."
EXECUTABLE=SQSProducer
CONFIGURATION=release

echo "Building $EXECUTABLE"
docker run --rm -v "$WORKSPACE":/workspace -w /workspace $DOCKER_IMAGE_NAME \
       bash -cl "swift build --product $EXECUTABLE -c $CONFIGURATION"
cp $WORKSPACE/.build/x86_64-unknown-linux-gnu/$CONFIGURATION/$EXECUTABLE .
