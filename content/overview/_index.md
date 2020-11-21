## Build your home container

Builds a container image with your username (`$USER`).

    make user


### Run your home container

First, copy `.env.example` to `.env`.  Adjust the values to your accounts.

    cp .env.exaple .env
    vi .env

Then generate configuration:

    make config

Then, bring up the home container:

    make up

Create an ssh alias named home to ssh host 127.0.0.1, port 2222, user `$USER`.  ssh into the alias:

    ssh home
