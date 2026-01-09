# Jenkins Example Workflow

This repository contains example Jenkins pipelines for running DBmaestro Agent commands based on a TaskID found in your repository.

The two main pipeline variants in this repo are:

- `enact-test/Jenkinsfile`
  - Behavior: This pipeline polls the repository and will accept a `DBM_TASK_ID` parameter if provided. If no parameter is supplied it will attempt to extract `TaskID:` from the latest commit message. If no TaskID is found the pipeline fails.
  - Use case: automated runs where you want the pipeline to detect a TaskID from commits, but also optionally allow manual override.

- `enact-test2/Jenkinsfile`
  - Behavior: This pipeline requires the `DBM_TASK_ID` parameter (no fallback). It validates that the provided TaskID appears in the repository (searches commit messages) before proceeding. This job does not poll SCM and is intended for explicit, parameter-driven runs.
  - Use case: safety-first, manual or triggered runs where you want to be certain the specified TaskID exists in the repo before making changes.

Common pipeline behavior
- Both pipelines perform these high-level actions (in order):
  1. Checkout the external repository `https://github.com/DBMaestroDev/source-control-example.git` using a configured GitHub credential.
  2. Determine `TASK_ID` (either from a parameter or by parsing commit messages — depending on pipeline).
  3. Create a DBmaestro package (Create Package stage).
  4. Run a Precheck (Precheck Package in DBmaestro stage).
  5. Optionally wait for manual verification (input step).
  6. Run the Upgrade step against a Release Source environment.
  7. Optionally require manual approval and then run the Production Upgrade.

Required Jenkins configuration
- Credentials (create these in Jenkins Credentials):
  - `gh_user_token` — a GitHub personal access token (used by the Git checkout).
  - `dbm_credentials` — DBmaestro account credentials stored as a username/password credential (the pipeline injects them as `DBM_USER` and `DBM_PASS`).

- Agent requirements:
  - The Jenkins agent running these pipelines must have Git and Java available in PATH.
  - The DBmaestro Agent JAR must be present on the agent machine at the path configured by the pipeline environment variable `DBM_JAR_PATH` (default in examples: `C:\Program Files (x86)\DBmaestro\DOP Server\Agent\DBmaestroAgent.jar`). Adjust as needed for your environment.

Parameters and environment variables (summary)
- `DBM_TASK_ID` (pipeline parameter)
  - `enact-test`: optional; if omitted, pipeline will attempt to parse TaskID from the latest commit message.
  - `enact-test2`: required; pipeline will fail if empty.
- `DBM_PROJECT_NAME` — name of the DBmaestro project the package belongs to (parameter / env variable depending on pipeline).
- `DBM_JAR_PATH` — filesystem path to DBmaestroAgent.jar on the agent.
- `DBM_AGENT_ENDPOINT` — the DBmaestro Agent server endpoint used in the `-Server` argument.
- `DBM_ENV_NAME_RS`, `DBM_ENV_NAME_PROD`, `DBM_ENV_NAME_DEV` — environment names used for release-source / production / dev upgrades (configured in environment block).
- `DBM_AUTH_TYPE` — authentication type passed to the DBmaestro agent command (e.g., Basic).

How to use
1. Create a new Jenkins Pipeline (or Multibranch) job.
2. Configure credentials in Jenkins as described above (`gh_user_token`, `dbm_credentials`).
3. Configure the pipeline script path to the desired Jenkinsfile in this repo:
   - `enact-test/Jenkinsfile` — poll-and-detect behavior.
   - `enact-test2/Jenkinsfile` — parameter-required + repository verification.
4. When running the job for `enact-test2`, supply the `DBM_TASK_ID` parameter with the TaskID to enact.
5. Ensure the Jenkins agent has Java and the DBmaestro JAR available at `DBM_JAR_PATH` (or edit the Jenkinsfile to point to your location).

Security notes
- Never commit DBmaestro usernames, passwords, tokens, or other secrets to source control. Use Jenkins Credentials (username/password and secret text) and reference them in the pipeline via `withCredentials`. The example pipelines are already written to use a `dbm_credentials` username/password credential and a `gh_user_token` for Git.


---
Generated: updated to document `enact-test` and `enact-test2` pipeline behaviors and required Jenkins configuration.
Jenkins Example Workflow