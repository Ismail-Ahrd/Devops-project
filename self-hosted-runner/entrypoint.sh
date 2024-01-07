#!/bin/sh

# Define the GitHub Actions Runner registration URL
registration_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
echo "Requesting registration URL at '${registration_url}'"

# Request registration token using GitHub Personal Token
payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PERSONAL_TOKEN}" ${registration_url})
export RUNNER_TOKEN=$(echo $payload | jq .token --raw-output)

# Configure the GitHub Actions Runner
./config.sh \
    --name $(hostname) \
    --token ${RUNNER_TOKEN} \
    --labels my-runner \
    --url https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY} \
    --work "/work" \
    --unattended \
    --replace

# Define a function to remove the runner in case of interruption
remove() {
    ./config.sh remove --unattended --token "${RUNNER_TOKEN}"
}

# Set up traps to remove the runner on INT and TERM signals
#When the pod or the container dies it will automatically go a head and run the remove() fun that removes the runner from github action.
trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

# Run the GitHub Actions Runner and wait for it to finish
./run.sh "$*" &

wait $!
