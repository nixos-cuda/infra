# hydra-channel-update-script

Usage:
```
hydra-channel-update-script <hydra_url> <github_app_client_id> <github_app_secret_key> <owner/repo> <branch_name>
```

This script does following:
- parses JSON data from the file named in `HYDRA_JSON` environment variable;
- checks if the build mentioned there succeeded;
- if it did, it fetches the commit hash of `nixpkgs` input of that build;
- then it updates specified branch in specified repo using provided GitHub app credentials.

Since it uses GitHub app, you need to create it in your org:
- go to your org's Settings, Developer settings, GitHub apps (https://github.com/organizations/ORG/settings/apps)
- click "New GitHub app", then potentially authenticate, then fill out at least:
  - *GitHub App name* - whatever you like, but must be unique for the all of GitHub
  - *Homepage URL* - any URL, doesn't have to be working
  - in *Webhook* uncheck *Active* since we won't use it
  - in *Permissions* under *Repository permissions* for *Contents* select *Read and write*
    - it means that the key for this app can override any content in the repo, so take care to set up neccessary branch protections as needed
  - under *Where can this GitHub App be installed?* select the appropriate option
- press *Create GitHub App*
- on the configuration screen for the new app:
  - take note of *Client ID* to pass as an argument to the hook
  - in *Private keys* section click *Generate a private key*, it will download a key to your machine, save it securely to pass to the app as well
- in the left menu click *Install App* and install it in the target organisation(s) for target repo(s)

This script is intended to be run in Hydra's RunCommand plugin. Here's a sample config:

```
<runcommand>
  job = nixos-cuda:channel-unstable:_tested
  command = hydra-channel-update-script https://hydra.nixos-cuda.org ig8Ib5DgPv2sDt38PjB0 private-key.pem nixos-cuda/nixpkgs nixos-unstable-cuda
</runcommand>
```
