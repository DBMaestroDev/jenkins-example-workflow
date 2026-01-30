# Jenkins Example Workflow

This repository contains example Jenkins pipelines for managing DBmaestro packages integrated with ServiceNow task/change request tracking.

## Pipeline Overview

The repository includes the following main pipelines:

### Create-Packages Pipeline
**File:** `Create-Packages/Jenkinsfile` (v1.0)

**Purpose:** Creates a DBmaestro package from Source Control based on a ServiceNow Task or CTask ID.

**Steps:**
1. Validates input parameters
2. Verifies that the provided Task ID exists in ServiceNow and is not closed
3. Creates a DBmaestro package
4. Posts a comment to the ServiceNow task indicating package creation
5. Performs a precheck of the package in DBmaestro
6. Posts a comment to the ServiceNow task indicating precheck completion
7. Optionally upgrades the package in the Release Source environment, with retry on failure

**Parameters:**
- `ServiceNow_Task_ID` (required) — ServiceNow Task or CTask ID (e.g., TASK0000001, SCTASK0000001, CTASK0000001)
- `DBMaestro_Project_Name` (required) — DBmaestro project name
- `Source_Control_Task_ID` (optional) — Source Control task ID; defaults to Task ID if empty
- `DBMaestro_Package_Name` (optional) — DBmaestro package name; defaults to Task ID if empty
- `Package_Already_Exist` (optional) — Skip package creation if package already exists
- `Upgrade_RS_Environment` (optional) — Upgrade package in Release Source environment after precheck

---

### Upgrade-Environment Pipeline
**File:** `Upgrade-Environment/Jenkinsfile` (v1.0)

**Purpose:** Upgrades a target environment with a list of packages.

**Steps:**
1. Validates input parameters
2. Verifies that the provided Task ID exists in ServiceNow and is not closed
3. Upgrades the target environment with the specified packages (with per-package retry/skip/abort logic)
4. Posts per-package success/failure notes to ServiceNow
5. Reports any failed packages

**Parameters:**
- `ServiceNow_Task_ID` (required) — ServiceNow Task or CTask ID
- `DBMaestro_Project_Name` (required) — DBmaestro project name
- `Target_Environment` (required) — Target environment prefix for upgrade (rs, qa, stage, prod)
- `DBMaestro_Package_Name` (optional) — Comma-separated list of package names; defaults to Task ID if empty

**Features:**
- Supports comma-separated package names for batch upgrades
- Per-package retry/skip/abort options on failure
- 1-hour timeout for user input prompts
- Per-package ServiceNow activity posting

---

### Get-Packages Pipeline
**File:** `Get-Package-List/Jenkinsfile`

**Purpose:** Retrieves and displays list of packages from a DBmaestro project.

**Steps:**
1. Queries DBmaestro Agent for enabled packages
2. Parses and displays package information in table format
3. Archives the packages.json file

**Parameters:**
- `DBMaestro_Project_Name` (required) — DBmaestro project name

---

### ServiceNow Integration Pipelines
Additional pipelines for ServiceNow workflow automation:
- `servicenow-change-workflow/Jenkinsfile` — Manages change requests with Release Source and Production upgrades
- `servicenow-task-process/Jenkinsfile` — Processes task-based workflows

---

## ServiceNow Task ID Support

The pipelines support three types of ServiceNow Task IDs:
- **TASK** — Standard service request task (uses `sc_task` table)
- **SCTASK** — Service catalog task (uses `sc_task` table)
- **CTASK** — Change task (uses `change_task` table)

The pipeline automatically detects the task type and queries the correct ServiceNow table.

---

## Required Jenkins Configuration

### Credentials
Create the following credentials in Jenkins Credentials store:

- **`JENKINS_DBA_USER`** — Username/password credential for ServiceNow API access
- **`servicenow-endpoint`** — Secret text containing the ServiceNow instance URL (e.g., https://dev317594.service-now.com)
- **`dbmaestro-user-automation-token`** — Username/password credential for DBmaestro Agent authentication

### Agent Requirements
- Jenkins agent running the pipelines must have:
  - **Java** (for running DBmaestroAgent.jar)
  - **PowerShell** 5.1 or higher (for REST API calls and script execution)
  
- **DBmaestro Agent JAR** must be present at the path configured in pipeline environment variables (default: `C:\Program Files (x86)\DBmaestro\DOP Server\Agent\DBmaestroAgent.jar`)

---

## Environment Variables

Common environment variables configured in pipelines:

- `DBM_JAR_PATH` — Filesystem path to DBmaestroAgent.jar on the agent
- `DBM_AGENT_ENDPOINT` — DBmaestro Agent server endpoint (e.g., localhost:8017)
- `DBM_PROJECT_NAME` — DBmaestro project name (derived from parameter)
- `DBM_ENV_NAME` — Target environment name (e.g., rs_CHGMTEST, qa_CHGMTEST)
- `DBM_AUTH_TYPE` — Authentication type for DBmaestro (e.g., DBmaestroAccount, Domain)
- `DBM_USE_SSL` — Enable SSL for DBmaestro communication (True/False)
- `SERVICENOW_TABLE` — ServiceNow table name (sc_task or change_task, auto-detected)
- `INPUT_TIMEOUT` — User input prompt timeout in seconds (default: 3600 = 1 hour)

---

## How to Use

1. **Create a new Jenkins Pipeline job**
   - New Item → Pipeline
   - Configure the pipeline script path to the desired Jenkinsfile

2. **Configure Jenkins Credentials** (as described above)
   - Manage Jenkins → Credentials → System → Global credentials
   - Add the required credentials

3. **Run the pipeline**
   - Provide the required parameters
   - Pipeline will validate parameters, query ServiceNow, execute DBmaestro commands, and post activity back to ServiceNow

4. **Monitor progress**
   - For operations with per-package execution, respond to input prompts within the timeout period (1 hour)
   - Review ServiceNow activity notes for success/failure status

---

## Security Notes

- **Never commit secrets** to source control
- Use Jenkins Credentials (username/password, secret text) for all sensitive data
- ServiceNow credentials must have API access permissions
- DBmaestro credentials must have appropriate project and environment permissions

---

## SSL/TLS Handling

The pipelines use `System.Net.WebClient` for ServiceNow API calls with the following SSL/TLS configuration:
- ServerCertificateValidationCallback enabled (bypasses self-signed cert warnings)
- TLS 1.1 and 1.2 support
- Certificate revocation list check disabled

---

Generated: Updated to document Create-Packages, Upgrade-Environment, and Get-Packages pipelines with ServiceNow integration.