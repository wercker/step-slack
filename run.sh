#!/bin/bash
#source build-esen.sh

# check if slack webhook url is present
if [ -z "$WERCKER_SLACK_NOTIFIER_URL" ]; then
  fail "Please provide a Slack webhook URL"
fi

# check if a '#' was supplied in the channel name
if [ "${WERCKER_SLACK_NOTIFIER_CHANNEL:0:1}" = '#' ]; then
  export WERCKER_SLACK_NOTIFIER_CHANNEL=${WERCKER_SLACK_NOTIFIER_CHANNEL:1}
fi

# if no username is provided use the default - werckerbot
if [ -z "$WERCKER_SLACK_NOTIFIER_USERNAME" ]; then
  export WERCKER_SLACK_NOTIFIER_USERNAME=werckerbot
fi

# if no icon-url is provided for the bot use the default wercker icon
if [ -z "$WERCKER_SLACK_NOTIFIER_ICON_URL" ]; then
  export WERCKER_SLACK_NOTIFIER_ICON_URL="https://secure.gravatar.com/avatar/a08fc43441db4c2df2cef96e0cc8c045?s=140"
fi

# check if this event is a build or deploy
if [ -n "$DEPLOY" ]; then
  # its a deploy!
  export ACTION="deploy ($WERCKER_DEPLOYTARGET_NAME)"
  export ACTION_URL=$WERCKER_DEPLOY_URL
else
  # its a build!
  export ACTION="build"
  export ACTION_URL=$WERCKER_BUILD_URL
fi

export MESSAGE="<$ACTION_URL|$ACTION> for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch $WERCKER_GIT_BRANCH"
export FALLBACK="$ACTION for $WERCKER_APPLICATION_NAME by $WERCKER_STARTED_BY has $WERCKER_RESULT on branch $WERCKER_GIT_BRANCH"
export COLOR="good"

if [ "$WERCKER_RESULT" = "failed" ]; then
  export MESSAGE="$MESSAGE at step: $WERCKER_FAILED_STEP_DISPLAY_NAME"
  export FALLBACK="$FALLBACK at step: $WERCKER_FAILED_STEP_DISPLAY_NAME"
  export COLOR="danger"
fi

if [ -n "$WERCKER_SLACK_NOTIFIER_CUSTOM_MESSAGE" ]; then
  # Override message with a custom one
  export MESSAGE=$WERCKER_SLACK_NOTIFIER_CUSTOM_MESSAGE
  export FALLBACK=$WERCKER_SLACK_NOTIFIER_CUSTOM_MESSAGE
fi

if [ -n "$WERCKER_SLACK_NOTIFIER_CUSTOM_COLOR" ]; then
  # Override message with a custom one
  export COLOR=$WERCKER_SLACK_NOTIFIER_CUSTOM_COLOR
fi


# construct the json
json="{"

# channels are optional, dont send one if it wasnt specified
if [ -n "$WERCKER_SLACK_NOTIFIER_CHANNEL" ]; then
    json=$json"\"channel\": \"#$WERCKER_SLACK_NOTIFIER_CHANNEL\","
fi

json=$json"
    \"username\": \"$WERCKER_SLACK_NOTIFIER_USERNAME\",
    \"icon_url\":\"$WERCKER_SLACK_NOTIFIER_ICON_URL\",
    \"attachments\":[
      {
        \"fallback\": \"$FALLBACK\",
        \"text\": \"$MESSAGE\",
        \"color\": \"$COLOR\"
      }
    ]
}"

# skip notifications if not interested in passed builds or deploys
if [ "$WERCKER_SLACK_NOTIFIER_NOTIFY_ON" = "failed" ]; then
	if [ "$WERCKER_RESULT" = "passed" ]; then
		return 0
	fi
fi

# skip notifications if not on the right branch
if [ -n "$WERCKER_SLACK_NOTIFIER_BRANCH" ]; then
    if [ "$WERCKER_SLACK_NOTIFIER_BRANCH" != "$WERCKER_GIT_BRANCH" ]; then
        return 0
    fi
fi

# post the result to the slack webhook
RESULT=$(curl -d "payload=$json" -s "$WERCKER_SLACK_NOTIFIER_URL" --output "$WERCKER_STEP_TEMP"/result.txt -w "%{http_code}")
cat "$WERCKER_STEP_TEMP/result.txt"

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No token is specified."
  fi

  if grep -Fqx "No hooks" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" "$WERCKER_STEP_TEMP/result.txt"; then
    fail "No text specified."
  fi
fi

if [ "$RESULT" = "404" ]; then
  fail "Subdomain or token not found."
fi
