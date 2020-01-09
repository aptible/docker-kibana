# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/kibana

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/kibana/status)](https://quay.io/repository/aptible/kibana)

Kibana as an Aptible App.

## Security considerations

TODO : this uses Elastic Security freatures, so authentication is controlled by Elasticsearch's security now https://www.elastic.co/blog/security-for-elasticsearch-is-now-free

TODO : tell them to use `FORCE_SSL`

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
     example, if you are using Elasticsearch 7.2, then you should substitute
     `$KIBANA_VERSION` with `7.2`.
    * Set `DATABASE_URL` to the URL of your Elasticsearch instance on Aptible
     (this is the connection string presented in the Aptible dashboard when you
     select your Elasticsearch instance).

    ```
    aptible deploy \
     --app "$HANDLE" \
     --docker-image "aptible/kibana-security:$KIBANA_VERSION" \
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

* `latest`: Currently Kibana 7.5
* `7.5`: For Elasticsearch 7.5.x
* `7.4`: For Elasticsearch 7.4.x


## Next steps

After adding the Endpoint, you can access your Kibana app using a browser.

The URL was shown in the output when you added the Endpoint (it looks like
`app-$ID.on-aptible.com`), but if you didn't see it, use the following command
to display it again:

```
aptible endpoints:list --app "$HANDLE"
```

When prompted for credentials, use the database username and password to get started.

To jump in to a view of your recent log messages, you can start by clicking the
"Discover" tab, which should default to viewing all log messages, most recent
first.


## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2019 [Aptible](https://www.aptible.com) and contributors.


  [0]: https://www.aptible.com/documentation/enclave/tutorials/expose-web-app.html
