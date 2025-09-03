FROM ruby:3.3

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs sqlite3 libsqlite3-dev git && \
    apt-get clean

# Set up app directory
WORKDIR /app

# Copy the source code
COPY . .

# Install bundler and dependencies
RUN gem install bundler && bundle install

# Default command
CMD [ "bash" ]
