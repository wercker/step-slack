#!/bin/bash

# check if slack webhook url is present
if [ ! -n "WERCKER_SLACK_URL" ]; then
    error "Please provide a Slack webhook URL"
fi

# get the channel name to post notifications to
if [ ! -n "WERCKER_SLACK_NOTIFIER_CHANNEL" ]; then
    error "Please provide a Slack channel to push notifications to"
fi

# check if a '#' was supplied in the channel name
if [[ $WERCKER_SLACK_NOTIFIER_CHANNEL == \#* ]]; then
  error "Please specify the channel without the '#'"
fi

# if no username is provided use the default - werckerbot
if [ ! -n "$WERCKER_SLACK_NOTIFIER_USERNAME" ]; then
  export WERCKER_SLACK_NOTIFIER_USERNAME=werckerbot
fi

# if no icon-url is provided for the bot use the default wercker icon
if [ ! -n "$WERCKER_SLACK_NOTIFIER_ICON_URL" ]; then
    export WERCKER_SLACK_NOTIFIER_ICON_URL="https://secure.gravatar.com/avatar/a08fc43441db4c2df2cef96e0cc8c045?s=140"
fi

# check if this event is a build or deploy
if [ -n "$BUILD" ]; then
    # its a build!
    export ACTION="build"
    export ACTION_URL=$WERCKER_BUILD_URL
elif [ -n "$DEPLOY" ]; then
    # its a deploy!
    export ACTION="deploy"
    export ACTION_URL=$WERCKER_DEPLOY_URL
fi

export MESSAGE="$ACTION for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch $WERCKER_GIT_BRANCH"

# construct the json
json="{
    \"channel\": \"$WERCKER_SLACK_NOTIFIER_CHANNEL\",
    \"username\": \"$WERCKER_SLACK_NOTIFIER_USERNAME\",
    \"text\":\"$MESSAGE\",
    \"icon_url\":\"$WERCKER_SLACK_NOTIFIER_ICON_URL\"
}"

# skip notifications if not interested in passed builds or deploys
if [ "$WERCKER_SLACK_NOTIFIER_NOTIFY_ON" = "failed" ]; then
	if [ "$WERCKER_RESULT" = "passed" ]; then
		return 0
	fi
fi

# post the result to the slack webhook
RESULT=`curl -d "payload=$json" -s "$SLACK_URL" --output $WERCKER_STEP_TEMP/result.txt -w "%{http_code}"`
