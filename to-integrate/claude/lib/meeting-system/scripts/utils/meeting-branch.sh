#!/usr/bin/env bash
# Sourced by the meeting scripts: the one place that knows how a meeting branch
# is named. A meeting branch takes the repository's single branch form (the
# rules-version-control skill's "Branch Names"), with `discuss` as its verb:
#   yyyy-mm-dd-hh-mm-discuss_<topic>
# The verb is what marks a branch as a meeting, so every script recognises one
# by that shape and reads the topic back from what follows `discuss_`.

MEETING_BRANCH_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}-[0-9]{2}-discuss_[a-z0-9]+(-[a-z0-9]+)*$'

# The branch name a meeting on <topic> opens now.
meeting_branch_name() {
  printf '%s-discuss_%s' "$(date +%Y-%m-%d-%H-%M)" "$1"
}

# Succeeds when <branch> is a meeting branch.
is_meeting_branch() {
  [[ "$1" =~ $MEETING_BRANCH_RE ]]
}

# The topic of meeting branch <branch>.
meeting_topic() {
  printf '%s' "${1#*-discuss_}"
}
