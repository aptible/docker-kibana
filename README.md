# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/kibana

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/kibana/status)](https://quay.io/repository/aptible/kibana)

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

1. Create a new App for Kibana. In the step that follows, we'll use `$HANDLE`
   anywhere that you should substitute the actual App handle you specified in
   this step.

    ```
    aptible apps:create "$HANDLE"
    ```

2. In a single `aptible deploy` command,

    * Deploy the appropriate Kibana version for your Elasticsearch Database. For
     example, if you are using Elasticsearch 6.2, then you should substitute
     `$KIBANA_VERSION` with `6.2`.
    * Set `AUTH_CREDENTIALS` to the username / password combination you want to
     use to access Kibana.
    * Set `DATABASE_URL` to the URL of your Elasticsearch instance on Aptible
     (this is the connection string presented in the Aptible dashboard when you
     select your Elasticsearch instance).

    ```
    aptible deploy \
     --app "$HANDLE" \
     --docker-image "aptible/kibana:$KIBANA_VERSION" \
     "AUTH_CREDENTIALS=username:password" \
     "DATABASE_URL=https://user:password@example.com" \
     FORCE_SSL=true
    ```

If this fails, review the troubleshooting instructions below.

3. Create an Endpoint to make the Kibana app accessible:

    ```
    aptible endpoints:https:create \
      --app "$HANDLE" \
      --default-domain \
      cmd
    ```

    For more options (e.g. to use your own domain) for the Endpoint, review our
    [documentation][0].

## Troubleshooting

You might encounter the following errors when attempting to deploy:

* _Unable to reach Elasticsearch server_: This means the `DATABASE_URL` you
  provided is incorrect, or points to an Elasticsearch Database that is not
  reachable from your Kibana app. Double-check that the `DATABASE_URL` you used
  matches your Elasticsearch Database's connection URL, and make sure that you
  are deploying Kibana in the Environment (or Stack) where your Elasticsearch
  Database is located. Correct the URL if it was invalid, or start over if you
  need to create the App in a different Environment.
* _Incorrect Kibana version detected_: This means the Kibana version you are
  attempting to deploy is not compatible with the Elasticsearch version you are
  using. Correct the Kibana version as instructed, then deploy again.


## Available Tags and Compatibility

* `latest`: Currently Kibana 6.5
* `6.5`: For Elasticserach 6.5.x
* `6.4`: For Elasticserach 6.4.x
* `6.3`: For Elasticserach 6.3.x
* `6.2`: For Elasticsearch 6.2.x
* `6.1`: For Elasticsearch 6.1.x
* `6.0`: For Elasticsearch 6.0.x
* `5.6`: For Elasticsearch 5.6.x
* `5.1`: (EOL 2018-06-08) For Elasticsearch 5.1.x
* `5.0`: (EOL 2018-04-26) For Elasticsearch 5.0.x
* `4.4`: (EOL 2017-08-02) For Elasticsearch 2.x
* `4.1`: (EOL 2016-11-10) For Elasticsearch 1.5.x


## Next steps

After adding the Endpoint, you can access your Kibana app using a browser.

The URL was shown in the output when you added the Endpoint (it looks like
`app-$ID.on-aptible.com`), but if you didn't see it, use the following command
to display it again:

```
aptible endpoints:list --app "$HANDLE"
```

When prompted for credentials, use the username and password you specified in
`AUTH_CREDENTIALS` when deploying.

If you're new to Kibana, try working through the [Kibana 10 minute walk
through][1] as an introduction.

To jump in to a view of your recent log messages, you can start by clicking the
"Discover" tab, which should default to viewing all log messages, most recent
first.


## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)


  [0]: https://www.aptible.com/documentation/enclave/tutorials/expose-web-app.html
  [1]: http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html
