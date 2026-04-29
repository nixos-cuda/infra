use anyhow::{Context, Result, anyhow};

#[derive(clap::Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    #[arg(long, requires = "private_key")]
    client_id: Option<String>,
    #[arg(long, requires = "client_id")]
    private_key: Option<std::path::PathBuf>,
}

#[derive(clap::Subcommand)]
enum Commands {
    UpdateChannel {
        #[arg(long)]
        hydra_url: String,
        #[arg(long)]
        repo_full_name: String,
        #[arg(long)]
        upstream_branch: String,
        #[arg(long)]
        branch: String,
    },
    SyncBranches {
        #[arg(long)]
        repo_full_name: String,
        #[arg(num_args=1..)]
        branches: Vec<String>,
    },
    ClonePR {
        #[arg(long, default_value = "nixos-cuda/nixpkgs")]
        repo_full_name: String,
        #[arg(long, default_value = "Clone of {html_url} for CI")]
        body: String,
        pr_url: reqwest::Url,
    },
}

fn main() -> Result<()> {
    use clap::Parser;
    let cli = Cli::parse();
    let get_token = move |client: &reqwest::blocking::Client,
                          repo_full_name: &str|
          -> Result<InstallationOrUserToken> {
        Ok(InstallationOrUserToken(
            match (cli.client_id, cli.private_key) {
                (None, None) => {
                    std::env::var("GITHUB_TOKEN").or_else(|err| match err {
                        std::env::VarError::NotPresent => {
                            eprintln!(
                                "GITHUB_TOKEN environment variable is not set, trying `gh auth token`"
                            );
                            let stdout = std::process::Command::new("gh")
                                .args(["auth", "token"])
                                .stderr(std::process::Stdio::inherit())
                                .output()
                                .context("failed to run `gh auth token`")?
                                .stdout;
                            // Trim trailing newline from stdout
                            Ok(String::from_utf8_lossy(&stdout[..stdout.len() - 1]).to_string())
                        }
                        std::env::VarError::NotUnicode(_) => {
                            Err(anyhow!(err).context("couldn't parse GITHUB_TOKEN environment variable"))
                        }
                    })?
                }
                (Some(client_id), Some(private_key)) => {
                    use rsa::pkcs1::DecodeRsaPrivateKey;
                    let private_key = rsa::RsaPrivateKey::read_pkcs1_pem_file(&private_key)
                        .with_context(|| {
                            format!("failed to read private key from file {:?}", private_key)
                        })?;
                    let app_token = make_app_jwt(client_id, private_key);
                    let installation_id = get_installation_for_repo(
                        client,
                        &app_token,
                        repo_full_name,
                    )
                    .with_context(|| {
                        format!("failed to get GitHub app installation for repo {repo_full_name}")
                    })?;
                    let installation_token =
                        get_installation_token(client, &app_token, installation_id).with_context(
                            || format!("failed to get token for installation {installation_id}"),
                        )?;
                    installation_token.0
                }
                (None, Some(_)) | (Some(_), None) => unreachable!("enforced by clap"),
            },
        ))
    };
    match cli.command {
        Commands::UpdateChannel {
            hydra_url,
            repo_full_name,
            upstream_branch,
            branch,
        } => update_channel(
            get_token,
            hydra_url,
            repo_full_name,
            upstream_branch,
            branch,
        ),
        Commands::SyncBranches {
            repo_full_name,
            branches,
        } => sync_branches(get_token, repo_full_name, branches),
        Commands::ClonePR {
            repo_full_name,
            body,
            pr_url,
        } => clone_pr(get_token, repo_full_name, body, pr_url),
    }
}

fn clone_pr(
    get_token: impl FnOnce(&reqwest::blocking::Client, &str) -> Result<InstallationOrUserToken>,
    repo_full_name: String,
    body: String,
    pr_url: reqwest::Url,
) -> Result<()> {
    if pr_url
        .host()
        .is_none_or(|host| host != url::Host::Domain("github.com"))
        || pr_url.scheme() != "https"
    {
        return Err(anyhow!("PR URL must start with https://github.com"));
    }
    let ["", org, repo, "pull", pr_num_str] = pr_url.path().split('/').collect::<Vec<_>>()[..]
    else {
        return Err(anyhow!("PR URL path must be /<org>/<repo>/pull/<pr_num>"));
    };
    let upstream_repo_full_name = format!("{org}/{repo}");
    let pr_num = pr_num_str.parse().context("couldn't parse PR number")?;

    // Prepare HTTP client
    let client = reqwest::blocking::Client::builder()
        .user_agent(concat!(
            env!("CARGO_PKG_NAME"),
            "/",
            env!("CARGO_PKG_VERSION"),
        ))
        .build()?;

    let token = get_token(&client, &repo_full_name)?;
    let pr = get_pr(&client, &token, &upstream_repo_full_name, pr_num)?;
    let head = format!("{}:{}", pr.head.repo.owner.login, pr.head.r#ref);
    let new_pr = create_pr(
        &client,
        &token,
        &repo_full_name,
        &pr.title,
        &head,
        &pr.head.repo.full_name,
        &pr.base.r#ref,
        &body.replace("{html_url}", &pr.html_url),
    )?;
    eprintln!("Created a new PR {}", new_pr.html_url);

    Ok(())
}

fn sync_branches(
    get_token: impl FnOnce(&reqwest::blocking::Client, &str) -> Result<InstallationOrUserToken>,
    repo_full_name: String,
    branches: Vec<String>,
) -> Result<()> {
    // Prepare HTTP client
    let client = reqwest::blocking::Client::builder()
        .user_agent(concat!(
            env!("CARGO_PKG_NAME"),
            "/",
            env!("CARGO_PKG_VERSION"),
        ))
        .build()?;

    let token = get_token(&client, &repo_full_name)?;

    let mut has_errors = false;
    for branch in branches {
        if let Err(err) = sync_branch(&client, &token, &repo_full_name, &branch) {
            eprintln!(
                "failed to sync branch {branch} in repo {repo_full_name} with the upstream: {err:?}"
            );
            has_errors = true;
        }
    }
    if has_errors {
        Err(anyhow!("failed to update some branches"))
    } else {
        Ok(())
    }
}

fn update_channel(
    get_token: impl FnOnce(&reqwest::blocking::Client, &str) -> Result<InstallationOrUserToken>,
    hydra_url: String,
    repo_full_name: String,
    upstream_branch: String,
    branch: String,
) -> Result<()> {
    // Parse Hydra's input JSON
    let hydra_json = read_hydra_json()?;
    if !hydra_json.finished || !matches!(hydra_json.build_status, BuildStatus::Succeeded) {
        eprintln!(
            "Build {} is not finished or is not successfull, aborting",
            hydra_json.build
        );
        return Ok(());
    }

    // Prepare HTTP client
    let client = reqwest::blocking::Client::builder()
        .user_agent(concat!(
            env!("CARGO_PKG_NAME"),
            "/",
            env!("CARGO_PKG_VERSION"),
        ))
        .build()?;

    // Get Nixpkgs commit SHA
    let build_evals = get_build_evals(&client, &hydra_url, hydra_json.build)
        .with_context(|| format!("failed to get evals for build {}", hydra_json.build))?;
    let last_eval = *build_evals.last().ok_or_else(|| {
        anyhow!(
            "build {} has no evals: {hydra_url}/build/{}/evals",
            hydra_json.build,
            hydra_json.build
        )
    })?;
    let eval = get_eval(&client, &hydra_url, last_eval)
        .with_context(|| format!("failed to get eval {last_eval}"))?;
    let commit_sha = eval.jobsetevalinputs.get("nixpkgs")
        .ok_or_else(|| anyhow!("eval input \"nixpkgs\" not found for eval {last_eval}: {hydra_url}/eval/{last_eval}#tabs-inputs"))?
        .revision.clone()
        .ok_or_else(|| anyhow!("eval input \"nixpkgs\" has no revision for eval {last_eval}: {hydra_url}/eval/{last_eval}#tabs-inputs"))?;
    eprintln!(
        "found Nixpkgs commit hash for build {} {commit_sha}",
        hydra_json.build
    );

    // Update branch
    let token = get_token(&client, &repo_full_name)?;
    sync_branch(&client, &token, &repo_full_name, &upstream_branch).with_context(|| {
        format!("failed to sync branch {branch} in repo {repo_full_name} with the upstream")
    })?;
    update_branch(&client, &token, &repo_full_name, &branch, &commit_sha).with_context(|| {
        format!("failed to update branch {branch} in repo {repo_full_name} to commit {commit_sha}")
    })?;
    eprintln!("updated branch {branch} in repo {repo_full_name} to commit {commit_sha}");
    Ok(())
}

struct AppToken(String);
struct InstallationToken(String);
struct InstallationOrUserToken(String);

/// Generate GitHub app token (JWT) from its private key.
/// https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-a-json-web-token-jwt-for-a-github-app
fn make_app_jwt(client_id: String, key: rsa::RsaPrivateKey) -> AppToken {
    use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
    let signer = rsa::pkcs1v15::SigningKey::<sha2::Sha256>::new(key);
    let jwt_header = URL_SAFE_NO_PAD.encode("{\"typ\":\"JWT\",\"alg\":\"RS256\"}") + ".";
    let now = chrono::Utc::now();
    let to_sign = jwt_header
        + URL_SAFE_NO_PAD
            .encode(
                serde_json::json!({
                    "iat": (now - chrono::TimeDelta::seconds(60)).timestamp(),
                    "exp": (now + chrono::TimeDelta::minutes(10)).timestamp(),
                    "iss": client_id,
                })
                .to_string()
                .as_str(),
            )
            .as_str();
    use rsa::signature::{SignatureEncoding, Signer};
    let signature = URL_SAFE_NO_PAD.encode(signer.sign(to_sign.as_bytes()).to_bytes());
    AppToken(to_sign + "." + &signature)
}

/// Get GitHub app installation ID for repository.
/// https://docs.github.com/en/rest/apps/apps#get-a-repository-installation-for-the-authenticated-app
fn get_installation_for_repo(
    http_client: &reqwest::blocking::Client,
    app_token: &AppToken,
    repo_full_name: &str,
) -> Result<u64> {
    #[derive(serde::Deserialize)]
    struct Response {
        id: u64,
    }
    Ok(http_client
        .get(format!(
            "https://api.github.com/repos/{repo_full_name}/installation",
        ))
        .bearer_auth(&app_token.0)
        .send()?
        .error_for_status_with_body()?
        .json::<Response>()?
        .id)
}

/// Get GitHub app's installation access token.
/// https://docs.github.com/en/rest/apps/apps#create-an-installation-access-token-for-an-app
fn get_installation_token(
    http_client: &reqwest::blocking::Client,
    app_token: &AppToken,
    installation_id: u64,
) -> Result<InstallationToken> {
    #[derive(serde::Deserialize)]
    struct Response {
        token: String,
        expires_at: chrono::DateTime<chrono::Utc>,
    }
    let resp = http_client
        .post(format!(
            "https://api.github.com/app/installations/{installation_id}/access_tokens",
        ))
        .bearer_auth(&app_token.0)
        .send()?
        .error_for_status_with_body()?
        .json::<Response>()?;
    eprintln!(
        "got a new installation token for {installation_id} valid until {}",
        resp.expires_at,
    );
    Ok(InstallationToken(resp.token))
}

/// Sync branch in a GitHub fork with the upstream repository.
/// https://docs.github.com/rest/branches/branches#sync-a-fork-branch-with-the-upstream-repository
fn sync_branch(
    http_client: &reqwest::blocking::Client,
    token: &InstallationOrUserToken,
    repo_full_name: &str,
    branch_name: &str,
) -> Result<()> {
    #[derive(serde::Serialize)]
    struct Request {
        branch: String,
    }
    http_client
        .post(format!(
            "https://api.github.com/repos/{repo_full_name}/merge-upstream",
        ))
        .bearer_auth(&token.0)
        .json(&Request {
            branch: branch_name.to_string(),
        })
        .send()?
        .error_for_status_with_body()?;
    Ok(())
}

/// Update branch on GitHub repo to the specified commit.
/// The commit must be present in this fork.
/// https://docs.github.com/rest/git/refs#update-a-reference
fn update_branch(
    http_client: &reqwest::blocking::Client,
    token: &InstallationOrUserToken,
    repo_full_name: &str,
    branch_name: &str,
    commit_sha: &str,
) -> Result<()> {
    #[derive(serde::Serialize)]
    struct Request {
        sha: String,
        force: bool,
    }
    http_client
        .patch(format!(
            "https://api.github.com/repos/{repo_full_name}/git/refs/heads/{branch_name}",
        ))
        .bearer_auth(&token.0)
        .json(&Request {
            sha: commit_sha.to_string(),
            force: true,
        })
        .send()?
        .error_for_status_with_body()?;
    Ok(())
}

#[derive(serde::Deserialize, Debug)]
struct SimpleUser {
    login: String,
}

#[derive(serde::Deserialize, Debug)]
struct Repository {
    full_name: String,
    owner: SimpleUser,
}

#[derive(serde::Deserialize, Debug)]
struct PullRequestBase {
    r#ref: String,
    repo: Repository,
}

#[derive(serde::Deserialize, Debug)]
struct PullRequest {
    html_url: String,
    title: String,
    head: PullRequestBase,
    base: PullRequestBase,
}

/// Get PR object from PR number
/// https://docs.github.com/rest/pulls/pulls#get-a-pull-request
fn get_pr(
    http_client: &reqwest::blocking::Client,
    token: &InstallationOrUserToken,
    repo_full_name: &str,
    pr_num: u64,
) -> Result<PullRequest> {
    Ok(http_client
        .get(format!(
            "https://api.github.com/repos/{repo_full_name}/pulls/{pr_num}",
        ))
        .bearer_auth(&token.0)
        .send()?
        .error_for_status_with_body()?
        .json()?)
}

/// Create GitHub pull request
/// https://docs.github.com/rest/pulls/pulls#create-a-pull-request
#[allow(clippy::too_many_arguments)]
fn create_pr(
    http_client: &reqwest::blocking::Client,
    token: &InstallationOrUserToken,
    repo_full_name: &str,
    title: &str,
    head: &str,
    head_repo: &str,
    base: &str,
    body: &str,
) -> Result<PullRequest> {
    #[derive(serde::Serialize, Debug)]
    struct Request<'a> {
        title: &'a str,
        head: &'a str,
        head_repo: &'a str,
        base: &'a str,
        body: &'a str,
        maintainer_can_modify: bool,
    }
    let request = Request {
        title,
        head,
        head_repo,
        base,
        body,
        maintainer_can_modify: false,
    };
    Ok(http_client
        .post(format!(
            "https://api.github.com/repos/{repo_full_name}/pulls",
        ))
        .bearer_auth(&token.0)
        .json(&request)
        .send()?
        .error_for_status_with_body()?
        .json()?)
}

#[derive(serde_repr::Deserialize_repr, Debug, PartialEq)]
#[repr(u8)]
#[allow(unused)]
pub enum BuildStatus {
    Succeeded = 0,
    #[serde(other)]
    Failed = 1,
}

#[derive(serde::Deserialize, Debug, PartialEq)]
#[serde(rename_all = "camelCase")]
struct HydraJson {
    build: u64,
    finished: bool,
    build_status: BuildStatus,
}

#[test]
fn test_actual_hydra_json() {
    let json = r#"{"startTime":1770974241,"license":null,"project":"nixos-cuda","system":"x86_64-linux","jobset":"channel-unstable","build":4,"description":null,"finished":true,"timestamp":1770974239,"buildStatus":0,"outputs":[{"path":"/nix/store/ibjafafzij6h1w29d3dvvh942wnkrawj-channel","name":"out"}],"nixName":"channel","job":"_tested","homepage":null,"metrics":[],"stopTime":1770974241,"event":"buildFinished","products":[],"drvPath":"/nix/store/aq9w1n2y9mdibm1m6mdm661g4jdv1slv-channel.drv"}"#;
    let res = serde_json::from_str::<HydraJson>(&json);
    let expected = HydraJson {
        build: 4,
        finished: true,
        build_status: BuildStatus::Succeeded,
    };
    assert!(
        matches!(res, Ok(ref res) if res == &expected),
        "{res:?} doesn't match {expected:?}"
    );
}

fn read_hydra_json() -> Result<HydraJson> {
    let filename = std::env::var("HYDRA_JSON")
        .map_err(|err| anyhow!("couldn't read environment variable HYDRA_JSON: {err}"))?;
    let contents = std::fs::read_to_string(&filename)
        .map_err(|err| anyhow!("couldn't read file \"{filename}\": {err}"))?;
    eprintln!("HYDRA_JSON contents:\n{contents}");
    serde_json::from_str(&contents).with_context(|| format!("error parsing file \"{filename}\""))
}

fn get_build_evals(
    client: &reqwest::blocking::Client,
    hydra_url: &str,
    build_id: u64,
) -> Result<Vec<u64>> {
    #[derive(serde::Deserialize)]
    struct Response {
        jobsetevals: Vec<u64>,
    }
    Ok(client
        .get(format!("{hydra_url}/build/{build_id}"))
        .header(reqwest::header::ACCEPT, "application/json")
        .send()?
        .error_for_status_with_body()?
        .json::<Response>()?
        .jobsetevals)
}

#[derive(serde::Deserialize)]
struct JobsetEvalInput {
    revision: Option<String>,
}

#[derive(serde::Deserialize)]
struct JobsetEval {
    jobsetevalinputs: std::collections::HashMap<String, JobsetEvalInput>,
}

fn get_eval(
    client: &reqwest::blocking::Client,
    hydra_url: &str,
    eval_id: u64,
) -> Result<JobsetEval> {
    Ok(client
        .get(format!("{hydra_url}/eval/{eval_id}"))
        .header(reqwest::header::ACCEPT, "application/json")
        .send()?
        .error_for_status_with_body()?
        .json()?)
}

// Convenience method to log response body along with the error
trait ResponseErrorWithBody {
    fn error_for_status_with_body(self) -> Result<Self>
    where
        Self: Sized;
}
impl ResponseErrorWithBody for reqwest::blocking::Response {
    fn error_for_status_with_body(self) -> Result<Self>
    where
        Self: Sized,
    {
        match self.error_for_status_ref() {
            Ok(_) => Ok(self),
            Err(err) => {
                let mut buf = Vec::new();
                use std::io::Read;
                self.take(1024).read_to_end(&mut buf)?;
                let body = String::from_utf8_lossy(&buf);
                Err(anyhow!("got response body: {}", body).context(err))
            }
        }
    }
}
