docker run --rm -it -v $HOME/.aws:/root/.aws sebsto/codebuild-swift /bin/bash

# docker run --rm  -v $HOME/.aws:/root/.aws \
#                  -v $(pwd)/..:/workspace  \
#                  sebsto/codebuild-swift   \
#                  /usr/local/bin/SQSProducer https://sqs.us-east-2.amazonaws.com/486652066693/cicd-command https://sqs.us-east-2.amazonaws.com/486652066693/cicd-response /workspace/test.sh 