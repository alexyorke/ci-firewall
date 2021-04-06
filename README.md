# ci-firewall

Shows how to set up a simple firewall on GitHub Actions that only allows NPM and GitHub's IPs, dynamically sourced on startup.

Disclaimer: I am not a security researcher, so I can't guarantee anything. Also, if another script has root access, then that script can trivially disable the firewall.
