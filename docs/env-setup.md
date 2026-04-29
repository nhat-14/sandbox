##### [Back To Main](../README.md)

## Environment Variables Setup

Before running any script, make sure to update the environment variable files according to your system setup.
The environment files are located here **(wfm.env and device-agent.env)**: cd $HOME/workspace/sandbox/scripts


**For wfm.sh and wfm-cli.sh script**

Environment file path:- $HOME/workspace/sandbox/scripts/wfm.env

Update the following variables:
```bash
export REGISTRY_HOST=<registry-machine-hostname-or-ip>
export WFM_HOST=<symphony-machine-hostname-or-ip>
export REGISTRY_PORT=8081
export WFM_PORT=8082
export WFM_SYMPHONY_BRANCH=main #it can be a tag also
export SANDBOX_REPO_BRANCH=main #it can be a tag also
```

**For k3s/docker device-agent.sh script**

Environment file path:- $HOME/workspace/sandbox/scripts/device-agent.env

Update the following variables:
```bash
export SANDBOX_REPO_BRANCH=main #it can be a tag also
export WFM_HOST=<wfm-machine-hostname-or-ip>
export REGISTRY_HOST=<registry-machine-hostname-or-ip>
```

