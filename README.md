# step-slack

A slack notifier written in `bash`.

[![wercker status](https://app.wercker.com/status/94f767fe85199d1f7f2dd064f36802bb/s "wercker status")](https://app.wercker.com/project/bykey/94f767fe85199d1f7f2dd064f36802bb)

## Usage

In your `wercker.yml` file add an afterstep in your build or deploy
section (or both) with the following contents:

```yaml
    after-steps:
        - slack-notifier:
            url: $SLACK_URL
            channel: notifications
            username: myamazingbotname
```

Where `$SLACK_URL` is a Slack webhook url (see the Slack integrations page to
set one up)

## Other optional fields

```yaml
icon_url: # a url that specifies an image to use as the avatar icon in Slack
notify_on: "failed" # just notify on failed builds or deploys
```


