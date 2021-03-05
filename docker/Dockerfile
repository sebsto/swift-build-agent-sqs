FROM swift:5.3.3-amazonlinux2

RUN /bin/yum install -y unzip && \
    /bin/curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    /bin/unzip awscliv2.zip && \
    ./aws/install

COPY ./SQSProducer /usr/local/bin

CMD /usr/local/bin/aws --version && swift --version
