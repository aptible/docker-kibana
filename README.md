# ![](https://gravatar.com/avatar/11d3bc4c3163e3d238d558d5c9d98efe?s=64) aptible/kibana

[![Docker Repository on Quay.io](https://quay.io/repository/aptible/kibana/status)](https://quay.io/repository/aptible/kibana)

Kibana 4.1.1 as an Aptible app.

## Installation and Usage

To run as an app on Aptible:

 1. Create an app in your [Aptible dashboard](https://dashboard.aptible.com) for Kibana. In the
    steps that follow, we'll use &lt;YOUR_KIBANA_APP_HANDLE&gt; anywhere that you should substitute the
    actual app handle the results from this step in the instructions.

 2. Use the [Aptible CLI](https://github.com/aptible/aptible-cli) to set AUTH_CREDENTIALS to the
    username/password you want to use to access the app. To set the user to "foo" and password
    to "bar", run:

    ```
    aptible config:set AUTH_CREDENTIALS=foo:bar --app <YOUR_KIBANA_APP_HANDLE>
    ```

 3. Use the [Aptible CLI](https://github.com/aptible/aptible-cli) to set DATABASE_URL to the
    URL of your Elasticsearch instance on Aptible (this is just the connection string presented
    in the Aptible dashboard when you select your Elasticsearch instance). If your URL is
    http://user:password@example.com, run:

    ```
    aptible config:set DATABASE_URL=http://user:password@example.com --app <YOUR_KIBANA_APP_HANDLE>
    ```

 4. (Optional) Kibana config options can be set for `default_route` and `kibana_index` which are then saved to the config.js:

    ```
    aptible config:set DEFAULT_ROUTE=/path/to/default --app <YOUR_KIBANA_APP_HANDLE>
    aptible config:set KIBANA_INDEX=your_index --app <YOUR_KIBANA_APP_HANDLE>
    ```

 5. Clone this repository and push it to your Aptible app:

    ```
    git clone https://github.com/aptible/docker-kibana.git
    cd docker-kibana
    git remote add aptible git@beta.aptible.com:<YOUR_KIBANA_APP_HANDLE>.git
    git push aptible master
    ```

You should be up and running now. If you have a default `*.on-aptible.com` VHOST, you're done. If not, add a custom VHOST to expose your Kibaba app to the Internet.

If you're new to Kibana, try working through the
[Kibana 10 minute walk through](http://www.elasticsearch.org/guide/en/kibana/current/using-kibana-for-the-first-time.html) as an introduction. To jump in to
a view of your recent log messages, you can start by clicking the "Discover" tab, which should default to viewing all log messages, most recent
first.

## Copyright and License

MIT License, see [LICENSE](LICENSE.md) for details.

Copyright (c) 2014 [Aptible](https://www.aptible.com) and contributors.

[<img src="https://s.gravatar.com/avatar/c386daf18778552e0d2f2442fd82144d?s=60" style="border-radius: 50%;" alt="@aaw" />](https://github.com/aaw)
