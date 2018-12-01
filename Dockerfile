# Extend from the official Elixir image
FROM elixir:latest

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force && mix local.rebar --force

COPY config/* config/
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app
WORKDIR /app

# Compile the project
RUN mix do deps.get, deps.compile

EXPOSE 4000
CMD ["mix", "phx.server"]