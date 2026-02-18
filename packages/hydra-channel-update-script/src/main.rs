use anyhow::{Context, Error, Result, anyhow};

fn make_app_jwt(client_id: String, key: rsa::RsaPrivateKey) -> String {
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
    to_sign + "." + &signature
}

fn get_installation_for_repo(
    http_client: &reqwest::blocking::Client,
    app_token: &String,
    repo_full_name: &String,
) -> Result<u64> {
    #[derive(serde::Deserialize)]
    struct Response {
        id: u64,
    }
    Ok(http_client
        .get(format!(
            "https://api.github.com/repos/{repo_full_name}/installation",
        ))
        .bearer_auth(app_token)
        .send()?
        .error_for_status_with_body()?
        .json::<Response>()?
        .id)
}

fn get_installation_token(
    http_client: &reqwest::blocking::Client,
    app_token: &String,
    installation_id: u64,
) -> Result<String> {
    #[derive(serde::Deserialize)]
    struct Response {
        token: String,
        expires_at: chrono::DateTime<chrono::Utc>,
    }
    let resp = http_client
        .post(format!(
            "https://api.github.com/app/installations/{installation_id}/access_tokens",
        ))
        .bearer_auth(app_token)
        .send()?
        .error_for_status_with_body()?
        .json::<Response>()?;
    eprintln!(
        "got a new installation token for {installation_id} valid until {}",
        resp.expires_at,
    );
    Ok(resp.token)
}

fn sync_branch(
    http_client: &reqwest::blocking::Client,
    token: &String,
    repo_full_name: &String,
    branch_name: &String,
) -> Result<()> {
    #[derive(serde::Serialize)]
    struct Request {
        branch: String,
    }
    http_client
        .post(format!(
            "https://api.github.com/repos/{repo_full_name}/merge-upstream",
        ))
        .bearer_auth(token)
        .json(&Request {
            branch: branch_name.to_string(),
        })
        .send()?
        .error_for_status_with_body()?;
    Ok(())
}

fn update_branch(
    http_client: &reqwest::blocking::Client,
    token: &String,
    repo_full_name: &String,
    branch_name: &String,
    commit_sha: &String,
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
        .bearer_auth(token)
        .json(&Request {
            sha: commit_sha.to_string(),
            force: true,
        })
        .send()?
        .error_for_status_with_body()?;
    Ok(())
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
    hydra_url: &String,
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
    hydra_url: &String,
    eval_id: u64,
) -> Result<JobsetEval> {
    Ok(client
        .get(format!("{hydra_url}/eval/{eval_id}"))
        .header(reqwest::header::ACCEPT, "application/json")
        .send()?
        .error_for_status_with_body()?
        .json()?)
}

fn usage() -> Error {
    anyhow!(
        "usage: {} <hydra_url> <github_app_client_id> <github_app_secret_key> <owner/repo> <upstream_branch_name> <branch_name>",
        std::env::args().next().unwrap()
    )
}

fn main() -> Result<()> {
    // Parse CLI args
    let mut args = std::env::args();
    let _ = args.next().ok_or_else(usage)?;
    let hydra_url = args.next().ok_or_else(usage)?;
    let client_id = args.next().ok_or_else(usage)?;
    let secret_key_path = args.next().ok_or_else(usage)?;
    let repo_full_name = args.next().ok_or_else(usage)?;
    let upstream_branch_name = args.next().ok_or_else(usage)?;
    let branch_name = args.next().ok_or_else(usage)?;
    if args.next().is_some() {
        return Err(usage());
    }

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
    use rsa::pkcs1::DecodeRsaPrivateKey;
    let private_key = rsa::RsaPrivateKey::read_pkcs1_pem_file(secret_key_path.as_str())
        .with_context(|| format!("failed to read private key from file {secret_key_path}"))?;
    let app_token = make_app_jwt(client_id, private_key);
    let installation_id = get_installation_for_repo(&client, &app_token, &repo_full_name)
        .with_context(|| {
            format!("failed to get GitHub app installation for repo {repo_full_name}")
        })?;
    let installation_token = get_installation_token(&client, &app_token, installation_id)
        .with_context(|| format!("failed to get token for installation {installation_id}"))?;
    sync_branch(
        &client,
        &installation_token,
        &repo_full_name,
        &upstream_branch_name,
    )
    .with_context(|| {
        format!("failed to sync branch {branch_name} in repo {repo_full_name} with the upstream")
    })?;
    update_branch(
        &client,
        &installation_token,
        &repo_full_name,
        &branch_name,
        &commit_sha,
    )
    .with_context(|| {
        format!(
            "failed to update branch {branch_name} in repo {repo_full_name} to commit {commit_sha}"
        )
    })?;
    eprintln!("updated branch {branch_name} in repo {repo_full_name} to commit {commit_sha}");
    Ok(())
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
