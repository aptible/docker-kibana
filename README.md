# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/kibana

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/kibana/status)](https://quay.io/repository/aptible/kibana)
[![Build Status](https://travis-ci.org/aptible/docker-kibana.svg?branch=master)](https://travis-ci.org/aptible/docker-kibana)

Kibana as an Aptible App.

## Security considerations

This app is configured through two environment variables: `AUTH_CREDENTIALS`
and `DATABASE_URL`. The former is used to authenticate Kibana users, and the
latter is used to make requests to a backend Elasticsearch instance.

In other words, **any user that can log in to Kibana can execute queries
against the upstream Elasticsearch instance using Kibana's credentials**.

This is probably what you want if you're deploying Kibana, but it means you
should make sure you choose strong passwords for `AUTH_CREDENTIALS`.

## Installation

To deploy Kibana as an App on Enclave:

1. Create a new App for Kibana. In the step that follows, we'll use `$HANDLE` anywhere that you should substitute the actual App handle you specified in this step.

    ```
    aptible apps:create "$HANDLE"
    ```

2. In a single `aptible deploy` command,
     * set AUTH_CREDENTIALS to the username/password you want to use to access the app
     * set DATABASE_URL to the URL of your Elasticsearch instance on Aptible (this is just the connection string presented in the Aptible dashboard when you select your Elasticsearch instance)

    ```
    aptible deploy --app "$HANDLE" --docker-image aptible/kibana "AUTH_CREDENTIALS=username:password" "DATABASE_URL=http://user:password@example.com"
    ```

Note: the Elasticsearch database connection specified by `DATABASE_URL`  must be reachable when this image is deployed, and the Kibana version must be compatible with the Elasticsearch version you are connecting to (see available version compatibility below).  This App will fail to start if these conditions are not met.


## Available Tags

* `latest`: Currently Kibana 6.2
* `6.2`: Kibana 6.2.2 (For Elasticsearch 6.2.x)
* `6.1`: Kibana 6.1.3 (for Elasticsearch 6.1.x)
* `6.0`: Kibana 6.0.1 (for Elasticsearch 6.0.x)
* `5.6`: Kibana 5.6.8 (for Elasticsearch 5.6.x)
* `5.1`: Kibana 5.1.2 (for Elasticsearch 5.1.x)
* `5.0`: Kibana 5.0.1 (for Elasticsearch 5.0.x)
* `4.4`: Kibana 4.4.2 (for Elasticsearch 2.x)
* `4.1`: Kibana 4.1.11 (for Elasticsearch 1.5.x)


## Next steps

You should be up and running now. If you have a default `*.on-aptible.com` VHOST, you're done. If not, add a custom VHOST to expose your Kibana app to the Internet.

If you're new to Kibana, try working through the
[Kibana 10 minute walk through](http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html) as an introduction. To jump in to
a view of your recent log messages, you can start by clicking the "Discover" tab, which should default to viewing all log messages, most recent
first.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
