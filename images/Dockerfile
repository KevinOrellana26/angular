FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl && apt-get clean

# Install node
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

# Install angular
RUN npm install -g @angular/cli
RUN ng new hello-world --interactive=false
WORKDIR /hello-world
EXPOSE 4500
CMD [ "ng", "serve", "--host", "0.0.0.0", "--port", "4500", "--disable-host-check"]